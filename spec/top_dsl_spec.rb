# frozen_string_literal: true

require 'tataru'

describe TopDsl do
  it 'creates a resource' do
    pool = ResourceTypePool.new
    pool.add_resource_desc(:file, BaseResourceDesc)

    dsl = TopDsl.new(pool)
    dsl.instance_eval do
      resource :file, 'somefile'
    end
    expect(dsl.resources['somefile']).to be_a(ResourceRepresentation)
  end

  it 'raises error if resource already made' do
    pool = ResourceTypePool.new
    pool.add_resource_desc(:file, BaseResourceDesc)
    pool.add_resource_desc(:file, BaseResourceDesc)

    dsl = TopDsl.new(pool)
    dsl.resource :file, 'somefile'
    expect { dsl.resource :file, 'somefile' }.to raise_error 'already defined: somefile'
  end

  it 'can handle more than one resource' do
    pool = ResourceTypePool.new
    pool.add_resource_desc(:file, BaseResourceDesc)

    dsl = TopDsl.new(pool)
    dsl.instance_eval do
      resource :file, 'somefile'
      resource :file, 'somefile2'
    end
    expect(dsl.resources.count).to eq 2
  end

  it 'has a dependency graph' do
    pool = ResourceTypePool.new
    pool.add_resource_desc(:file, BaseResourceDesc)

    dsl = TopDsl.new(pool)
    dsl.instance_eval do
      resource :file, 'somefile'
      resource :file, 'somefile2'
    end
    expect(dsl.dep_graph).to eq( 'somefile' => [], 'somefile2' => [] )
  end

  it 'has a dependency graph that shows dependency' do
    pool = ResourceTypePool.new
    pool.add_resource_desc(:file, BaseResourceDesc)

    allow_any_instance_of(BaseResourceDesc).to receive(:mutable_fields) { [:content] }
    allow_any_instance_of(BaseResourceDesc).to receive(:output_fields) { [:created_at] }

    dsl = TopDsl.new(pool)
    dsl.instance_eval do
      f = resource :file, 'somefile'

      resource :file, 'somefile2' do
        content f.created_at 
      end
    end
    expect(dsl.dep_graph).to eq( 'somefile' => [], 'somefile2' => ['somefile'] )
  end
end
