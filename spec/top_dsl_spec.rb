# frozen_string_literal: true

require 'tataru'

describe Tataru::TopDsl do
  it 'creates a resource' do
    pool = Tataru::ResourceTypePool.new
    pool.add_resource_desc(:file, Tataru::BaseResourceDesc)

    dsl = Tataru::TopDsl.new(pool)
    dsl.instance_eval do
      resource :file, 'somefile'
    end
    expect(dsl.resources['somefile']).to be_a(Tataru::Representations::ResourceRepresentation)
  end

  it 'raises error if resource already made' do
    pool = Tataru::ResourceTypePool.new
    pool.add_resource_desc(:file, Tataru::BaseResourceDesc)
    pool.add_resource_desc(:file, Tataru::BaseResourceDesc)

    dsl = Tataru::TopDsl.new(pool)
    dsl.resource :file, 'somefile'
    expect { dsl.resource :file, 'somefile' }.to raise_error 'already defined: somefile'
  end

  it 'can handle more than one resource' do
    pool = Tataru::ResourceTypePool.new
    pool.add_resource_desc(:file, Tataru::BaseResourceDesc)

    dsl = Tataru::TopDsl.new(pool)
    dsl.instance_eval do
      resource :file, 'somefile'
      resource :file, 'somefile2'
    end
    expect(dsl.resources.count).to eq 2
  end

  it 'has a dependency graph' do
    pool = Tataru::ResourceTypePool.new
    pool.add_resource_desc(:file, Tataru::BaseResourceDesc)

    dsl = Tataru::TopDsl.new(pool)
    dsl.instance_eval do
      resource :file, 'somefile'
      resource :file, 'somefile2'
    end
    expect(dsl.dep_graph).to eq( 'somefile' => [], 'somefile2' => [] )
  end

  it 'has a dependency graph that shows dependency' do
    pool = Tataru::ResourceTypePool.new
    pool.add_resource_desc(:file, Tataru::BaseResourceDesc)

    allow_any_instance_of(Tataru::BaseResourceDesc).to receive(:mutable_fields) { [:content] }
    allow_any_instance_of(Tataru::BaseResourceDesc).to receive(:output_fields) { [:created_at] }

    dsl = Tataru::TopDsl.new(pool)
    dsl.instance_eval do
      f = resource :file, 'somefile'

      resource :file, 'somefile2' do
        content f.created_at 
      end
    end
    expect(dsl.dep_graph).to eq( 'somefile' => [], 'somefile2' => ['somefile'] )
  end
end
