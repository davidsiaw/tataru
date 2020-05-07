# frozen_string_literal: true

require 'tataru'

describe Compiler do
  it 'outputs the correct default format' do
    dsl = TopDsl.new(ResourceTypePool.new)
    compiler = Compiler.new(dsl)
    expect(compiler.instr_hash).to eq(
      init: {
        labels: {},
        remote_ids: {},
        rom: {}
      },
      instructions: [:init, :end]
    )
  end

  it 'outputs top instructions and subroutine instructions' do
    dsl = TopDsl.new(ResourceTypePool.new)
    compiler = Compiler.new(dsl)

    allow(compiler).to receive(:top_instructions) { [:meow] }
    allow(compiler).to receive(:subroutine_instructions) { [:woof] }

    expect(compiler.instr_hash).to eq(
      init: {
        labels: {},
        remote_ids: {},
        rom: {}
      },
      instructions: [:meow, :woof]
    )
  end

  it 'wraps instructions with init and end' do
    dsl = TopDsl.new(ResourceTypePool.new)
    compiler = Compiler.new(dsl)

    allow(compiler).to receive(:generate_top_instructions) { [:meow] }
    
    expect(compiler.top_instructions).to eq [:init, :meow, :end]
  end

  it 'makes all the subroutine instructions mixed in' do
    dsl = TopDsl.new(ResourceTypePool.new)
    compiler = Compiler.new(dsl)

    a = double('SubroutineCompiler')
    b = double('SubroutineCompiler')

    allow(a).to receive(:body_instructions) { [:meow, :purr] }
    allow(b).to receive(:body_instructions) { [:pant, :woof] }
    allow(compiler).to receive(:subroutines) { {a: a, b: b} }

    expect(compiler.subroutine_instructions).to eq [:meow, :purr, :pant, :woof]
  end

  it 'assigns the correct numbers to labels' do
    dsl = TopDsl.new(ResourceTypePool.new)
    compiler = Compiler.new(dsl)

    a = double('SubroutineCompiler')
    b = double('SubroutineCompiler')

    allow(a).to receive(:body_instructions) { [:meow, :purr, :drink_milk] }
    allow(b).to receive(:body_instructions) { [:pant, :woof] }

    allow(a).to receive(:label) { :cat }
    allow(b).to receive(:label) { :dog }

    allow(compiler).to receive(:subroutines) { {a: a, b: b} }

    expect(compiler.generate_labels).to eq(cat: 2, dog: 5)
  end

  it 'generates the right subroutines' do
    dsl = TopDsl.new(ResourceTypePool.new)
    compiler = Compiler.new(dsl)

    dummy = double('SubroutineCompiler')
    allow(dummy).to receive(:call_instruction)

    dummy_subroutine_hash = double('Hash')
    allow(compiler).to receive(:subroutines) { dummy_subroutine_hash }

    allow(dsl).to receive(:dep_graph) { { a: [:b], c: [:b], b: [] } }

    expect(dummy_subroutine_hash).to receive(:[]).with('a') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('a_check') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('b') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('b_check') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('c') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('c_check') { dummy }

    compiler.generate_top_instructions
  end

  it 'generates create instructions by default' do
    dsl = TopDsl.new(ResourceTypePool.new)
    compiler = Compiler.new(dsl)

    cat = ResourceRepresentation.new('ccat', BaseResourceDesc.new, {})
    dog = ResourceRepresentation.new('ddog', BaseResourceDesc.new, {})
    allow(dsl).to receive(:resources) do
      {
        'cat' => cat,
        'dog' => dog
      }
    end

    expect(SubroutineCompiler).to receive(:new).with(cat, :create)
    expect(SubroutineCompiler).to receive(:new).with(cat, :check_create)
    
    expect(SubroutineCompiler).to receive(:new).with(dog, :create)
    expect(SubroutineCompiler).to receive(:new).with(dog, :check_create)

    expect(compiler.generate_subroutines.keys).to eq [
      'cat', 'cat_check', 'dog', 'dog_check'
    ]
  end
end
