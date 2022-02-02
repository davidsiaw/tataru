# frozen_string_literal: true

require 'tataru'

describe Tataru::Compiler do
  it 'outputs the correct default format' do
    dsl = Tataru::TopDsl.new(Tataru::ResourceTypePool.new)
    compiler = Tataru::Compiler.new(dsl, false)
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
    dsl = Tataru::TopDsl.new(Tataru::ResourceTypePool.new)
    compiler = Tataru::Compiler.new(dsl, false)

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
    dsl = Tataru::TopDsl.new(Tataru::ResourceTypePool.new)
    compiler = Tataru::Compiler.new(dsl, false)

    allow(compiler).to receive(:generate_top_instructions) { [:meow] }
    
    expect(compiler.top_instructions).to eq [:init, :meow, :end]
  end

  it 'makes all the subroutine instructions mixed in' do
    dsl = Tataru::TopDsl.new(Tataru::ResourceTypePool.new)
    compiler = Tataru::Compiler.new(dsl, false)

    a = double('SubroutineCompiler')
    b = double('SubroutineCompiler')

    allow(a).to receive(:body_instructions) { [:meow, :purr] }
    allow(b).to receive(:body_instructions) { [:pant, :woof] }
    allow(compiler).to receive(:subroutines) { {a: a, b: b} }

    expect(compiler.subroutine_instructions).to eq [:meow, :purr, :pant, :woof]
  end

  it 'assigns the correct numbers to labels' do
    dsl = Tataru::TopDsl.new(Tataru::ResourceTypePool.new)
    compiler = Tataru::Compiler.new(dsl, false)

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
    dsl = Tataru::TopDsl.new(Tataru::ResourceTypePool.new)
    compiler = Tataru::Compiler.new(dsl, false)

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
    dsl = Tataru::TopDsl.new(Tataru::ResourceTypePool.new)
    compiler = Tataru::Compiler.new(dsl, false)

    cat = Tataru::Representations::ResourceRepresentation.new('ccat', Tataru::BaseResourceDesc.new, {})
    dog = Tataru::Representations::ResourceRepresentation.new('ddog', Tataru::BaseResourceDesc.new, {})
    allow(dsl).to receive(:resources) do
      {
        'cat' => cat,
        'dog' => dog
      }
    end

    expect(Tataru::SubroutineCompiler).to receive(:new).with(cat, false, :create)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(cat, false, :check_create)

    expect(Tataru::SubroutineCompiler).to receive(:new).with(cat, false, :commit_create)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(cat, false, :finish_create)

    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :create)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :check_create)

    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :commit_create)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :finish_create)

    expect(compiler.generate_subroutines.keys).to eq [
      'ccat_start', 'ccat_check', 'ccat_commit', 'ccat_finish',
      'ddog_start', 'ddog_check', 'ddog_commit', 'ddog_finish'
    ]
  end

  it 'generates delete instructions for extant names' do
    dsl = Tataru::TopDsl.new(Tataru::ResourceTypePool.new)
    compiler = Tataru::Compiler.new(dsl, false, { 'thing' => 'BaseResourceDesc' })

    expect(Tataru::SubroutineCompiler).to receive(:new).with(instance_of(Tataru::Representations::ResourceRepresentation), false, :delete)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(instance_of(Tataru::Representations::ResourceRepresentation), false, :check_delete)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(instance_of(Tataru::Representations::ResourceRepresentation), false, :commit_delete)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(instance_of(Tataru::Representations::ResourceRepresentation), false, :finish_delete)

    expect(compiler.generate_subroutines.keys).to eq [
      'thing_start', 'thing_check', 'thing_commit', 'thing_finish'
    ]
  end

  it 'generates update instructions for extant names that are set' do
    dsl = Tataru::TopDsl.new(Tataru::ResourceTypePool.new)
    compiler = Tataru::Compiler.new(dsl, false, { 'thong' => 'BaseResourceDesc' })

    dog = Tataru::Representations::ResourceRepresentation.new('ddog', Tataru::BaseResourceDesc.new, {})
    allow(dsl).to receive(:resources) do
      {
        'thong' => dog
      }
    end

    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :missing_create)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :missing_create_check)

    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :update)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :check_update)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :commit_update)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :finish_update)

    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :modify)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :modify_check)

    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :recreate)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :recreate_check)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :recreate_commit)
    expect(Tataru::SubroutineCompiler).to receive(:new).with(dog, false, :recreate_finish)

    expect(compiler.generate_subroutines.keys).to eq [
      'ddog_start', 'ddog_check', 'ddog_commit', 'ddog_finish',
      'ddog_modify', 'ddog_modify_check',
      'ddog_recreate', 'ddog_recreate_check',
      'ddog_recreate_commit', 'ddog_recreate_finish',
      "ddog_missing_create", "ddog_missing_create_check"
    ]
  end
end
