# frozen_string_literal: true

require 'tataru'

describe Tataru::Taru do
  it 'makes one resource' do
    TestEnvironment.instance.clear!

    rtp = Tataru::ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    
    ttr = Tataru::Taru.new(rtp) do
      resource :file, 'file' do
        name 'something1.txt'
        contents '123'
      end
    end

    travel_to Time.new(2011, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        break unless ttr.step
      end
    end

    expect(ttr.error).to be_nil

    expect(ttr.oplog).to eq [
      {operation: 'CREATE', resource: 'file'},
      {operation: 'CHECK_CREATE', resource: 'file'}
    ]

    expect(TestEnvironment.instance.files).to eq(
      'something1.txt' => {
        name: 'something1.txt',
        contents: '123',
        created_at: "2011-01-01 00:00:00 UTC",
        updated_at: "2011-01-01 00:00:00 UTC"
      }
    )

    expect(ttr.state).to eq(
      'file' => {
        name: 'something1.txt',
        desc: TestFileResourceDesc,
        dependencies: []
      }
    )
  end

  it 'builds and deletes one resource' do
    TestEnvironment.instance.clear!

    TestEnvironment.instance.files = {
      'something1.txt' => {
        contents: 'asd',
        created_at: "2010-01-01 00:00:00 UTC",
        updated_at: "2010-01-01 00:00:00 UTC"
      }
    }

    rtp = Tataru::ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    remote_ids = {
      'file1' => {
        name: 'something1.txt',
        desc: 'TestFileResourceDesc',
        dependencies: []
      }
    }

    ttr = Tataru::Taru.new(rtp, remote_ids) do
      resource :file, 'file2' do
        name 'something2.txt'
        contents '123'
      end
    end

    travel_to Time.new(2011, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        break unless ttr.step
      end
    end

    expect(ttr.error).to be_nil

    expect(ttr.oplog).to eq [
      {operation: 'DELETE', resource: 'file1'},
      {operation: 'CREATE', resource: 'file2'},
      {operation: 'CHECK_DELETE', resource: 'file1'},
      {operation: 'CHECK_CREATE', resource: 'file2'}
    ]

    expect(TestEnvironment.instance.files).to eq(
      'something2.txt' => {
        name: 'something2.txt',
        contents: '123',
        created_at: "2011-01-01 00:00:00 UTC",
        updated_at: "2011-01-01 00:00:00 UTC"
      }
    )

    expect(ttr.state).to eq(
      'file2' => {
        name: 'something2.txt',
        desc: TestFileResourceDesc,
        dependencies: []
      }
    )
  end
end
