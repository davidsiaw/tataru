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

    expect(dummy_subroutine_hash).to receive(:[]).with('b_start') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('b_check') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('b_commit') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('b_finish') { dummy }

    expect(dummy_subroutine_hash).to receive(:[]).with('a_start') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('a_check') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('a_commit') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('a_finish') { dummy }

    expect(dummy_subroutine_hash).to receive(:[]).with('c_start') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('c_check') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('c_commit') { dummy }
    expect(dummy_subroutine_hash).to receive(:[]).with('c_finish') { dummy }

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

    expect(SubroutineCompiler).to receive(:new).with(cat, :commit_create)
    expect(SubroutineCompiler).to receive(:new).with(cat, :finish_create)

    expect(SubroutineCompiler).to receive(:new).with(dog, :create)
    expect(SubroutineCompiler).to receive(:new).with(dog, :check_create)

    expect(SubroutineCompiler).to receive(:new).with(dog, :commit_create)
    expect(SubroutineCompiler).to receive(:new).with(dog, :finish_create)

    expect(compiler.generate_subroutines.keys).to eq [
      'ccat_start', 'ccat_check', 'ccat_commit', 'ccat_finish',
      'ddog_start', 'ddog_check', 'ddog_commit', 'ddog_finish'
    ]
  end

  it 'generates delete instructions for extant names' do
    dsl = TopDsl.new(ResourceTypePool.new)
    compiler = Compiler.new(dsl, { 'thing' => 'BaseResourceDesc' })

    expect(SubroutineCompiler).to receive(:new).with(instance_of(ResourceRepresentation), :delete)
    expect(SubroutineCompiler).to receive(:new).with(instance_of(ResourceRepresentation), :check_delete)
    expect(SubroutineCompiler).to receive(:new).with(instance_of(ResourceRepresentation), :commit_delete)
    expect(SubroutineCompiler).to receive(:new).with(instance_of(ResourceRepresentation), :finish_delete)

    expect(compiler.generate_subroutines.keys).to eq [
      'thing_start', 'thing_check', 'thing_commit', 'thing_finish'
    ]
  end

  it 'generates update instructions for extant names that are set' do
    dsl = TopDsl.new(ResourceTypePool.new)
    compiler = Compiler.new(dsl, { 'thong' => 'BaseResourceDesc' })

    dog = ResourceRepresentation.new('ddog', BaseResourceDesc.new, {})
    allow(dsl).to receive(:resources) do
      {
        'thong' => dog
      }
    end

    expect(SubroutineCompiler).to receive(:new).with(dog, :update)
    expect(SubroutineCompiler).to receive(:new).with(dog, :check_update)
    expect(SubroutineCompiler).to receive(:new).with(dog, :commit_update)
    expect(SubroutineCompiler).to receive(:new).with(dog, :finish_update)

    expect(compiler.generate_subroutines.keys).to eq [
      'ddog_start', 'ddog_check', 'ddog_commit', 'ddog_finish'
    ]
  end
end
