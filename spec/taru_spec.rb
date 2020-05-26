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
        desc: 'TestFileResourceDesc',
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
        desc: 'TestFileResourceDesc',
        dependencies: []
      }
    )
  end

  it 'builds and deletes one overlapping resource' do
    TestEnvironment.instance.clear!

    TestEnvironment.instance.servers = [
      {
        size: 'BIG',
        created_at: "2010-01-01 00:00:00 UTC"
      }
    ]

    rtp = Tataru::ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    rtp.add_resource_desc(:server, TestServerResourceDesc)
    remote_ids = {
      'oldserv' => {
        name: 'server0',
        desc: 'TestServerResourceDesc',
        dependencies: []
      }
    }

    ttr = Tataru::Taru.new(rtp, remote_ids) do
      s = resource :server, 'serv' do
        size 'SMOL'
      end

      resource :file, 'file1' do
        name 'something2.txt'
        contents s.created_at
      end
    end

    travel_to Time.new(2015, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        break unless ttr.step
      end
    end

    expect(ttr.error).to be_nil

    expect(ttr.oplog).to eq [
      {operation: 'CREATE', resource: 'serv'},
      {operation: 'CHECK_CREATE', resource: 'serv'},
      {operation: 'CREATE', resource: 'file1'},
      {operation: 'CHECK_CREATE', resource: 'file1'},
      {operation: 'DELETE', resource: 'oldserv'},
      {operation: 'CHECK_DELETE', resource: 'oldserv'}
    ]

    expect(TestEnvironment.instance.servers).to eq [
      nil,
      {
        size: 'SMOL',
        created_at: "2015-01-01 00:00:00 UTC"
      }
    ]

    expect(ttr.state).to eq(
      'file1' => {
        name: 'something2.txt',
        desc: 'TestFileResourceDesc',
        dependencies: ['serv']
      },
      'serv' => {
        name: 'server1',
        desc: 'TestServerResourceDesc',
        dependencies: []
      }
    )
  end

  it 'performs mutable update' do
    TestEnvironment.instance.clear!

    TestEnvironment.instance.files = {
      'ddd.txt' => {
        name: 'ddd.txt',
        contents: 'asd',
        created_at: "2010-01-01 00:00:00 UTC",
        updated_at: "2010-01-01 00:00:00 UTC"
      }
    }

    rtp = Tataru::ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    remote_ids = {
      'file' => {
        name: 'ddd.txt',
        desc: 'TestFileResourceDesc',
        dependencies: []
      }
    }

    ttr = Tataru::Taru.new(rtp, remote_ids) do
      resource :file, 'file' do
        name 'ddd.txt'
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
      {operation: 'READ', resource: 'file'},
      {operation: 'RESCMP', resource: 'file'},
      {operation: 'UPDATE', resource: 'file'},
      {operation: 'CHECK_UPDATE', resource: 'file'}
    ]

    expect(TestEnvironment.instance.files).to eq(
      'ddd.txt' => {
        name: 'ddd.txt',
        contents: '123',
        created_at: "2010-01-01 00:00:00 UTC",
        updated_at: "2011-01-01 00:00:00 UTC"
      }
    )

    expect(ttr.state).to eq(
      'file' => {
        name: 'ddd.txt',
        desc: 'TestFileResourceDesc',
        dependencies: []
      }
    )
  end

  it 'performs immutable update' do
    TestEnvironment.instance.clear!

    TestEnvironment.instance.files = {
      'ggg.txt' => {
        name: 'ggg.txt',
        contents: 'asd',
        created_at: "2010-01-01 00:00:00 UTC",
        updated_at: "2010-01-01 00:00:00 UTC"
      }
    }

    rtp = Tataru::ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    remote_ids = {
      'file' => {
        name: 'ggg.txt',
        desc: 'TestFileResourceDesc',
        dependencies: []
      }
    }

    ttr = Tataru::Taru.new(rtp, remote_ids) do
      resource :file, 'file' do
        name 'fff.txt'
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
      {operation: 'READ', resource: 'file'},
      {operation: 'RESCMP', resource: 'file'},
      {operation: 'DELETE', resource: 'file'},
      {operation: 'CHECK_DELETE', resource: 'file'},
      {operation: 'CREATE', resource: 'file'},
      {operation: 'CHECK_CREATE', resource: 'file'}
    ]

    expect(TestEnvironment.instance.files).to eq(
      'fff.txt' => {
        name: 'fff.txt',
        contents: '123',
        created_at: "2011-01-01 00:00:00 UTC",
        updated_at: "2011-01-01 00:00:00 UTC"
      }
    )

    expect(ttr.state).to eq(
      'file' => {
        name: 'fff.txt',
        desc: 'TestFileResourceDesc',
        dependencies: []
      }
    )
  end

  it 'recreates an overlapping resource' do
    TestEnvironment.instance.clear!

    TestEnvironment.instance.servers = [
      {
        size: 'A',
        created_at: "2010-01-01 00:00:00 UTC"
      }
    ]

    TestEnvironment.instance.ip_addresses = {
      '2.3.4.2' => 'server0'
    }

    rtp = Tataru::ResourceTypePool.new
    rtp.add_resource_desc(:ip_address, TestIpAddressResourceDesc)
    rtp.add_resource_desc(:server, TestServerResourceDesc)
    remote_ids = {
      'serv' => {
        name: 'server0',
        desc: 'TestServerResourceDesc',
        dependencies: []
      },
      'ip' => {
        name: '2.3.4.2',
        desc: 'TestIpAddressResourceDesc',
        dependencies: ['serv']
      }
    }

    ttr = Tataru::Taru.new(rtp, remote_ids) do
      s = resource :server, 'serv' do
        size 'B'
      end

      resource :ip_address, 'ip' do
        server_id s
      end
    end

    travel_to Time.new(2015, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        break unless ttr.step
      end
    end

    #puts runner.memory.error.backtrace.to_yaml

    expect(ttr.error).to be_nil

    expect(ttr.oplog).to eq [
      {operation: 'READ', resource: 'serv'},
      {operation: 'RESCMP', resource: 'serv'},
      {operation: 'MARK_DELETABLE', resource: 'serv'},
      {operation: 'CREATE', resource: 'serv'},
      {operation: 'CHECK_CREATE', resource: 'serv'},
      {operation: 'READ', resource: 'ip'},
      {operation: 'RESCMP', resource: 'ip'},
      {operation: 'UPDATE', resource: 'ip'},
      {operation: 'CHECK_UPDATE', resource: 'ip'},
      {operation: 'DELETE', resource: '_deletable_serv'},
      {operation: 'CHECK_DELETE', resource: '_deletable_serv'}
    ]

    expect(TestEnvironment.instance.servers).to eq [
      nil,
      {
        size: 'B',
        created_at: "2015-01-01 00:00:00 UTC"
      }
    ]

    expect(TestEnvironment.instance.ip_addresses).to eq(
      '2.3.4.2' => 'server1'
    )

    expect(ttr.state).to eq(
      'serv' => {
        name: 'server1',
        desc: 'TestServerResourceDesc',
        dependencies: []
      },
      'ip' => {
        name: '2.3.4.2',
        desc: 'TestIpAddressResourceDesc',
        dependencies: ['serv']
      }
    )
  end

  it 'builds multiple resources' do
    TestEnvironment.instance.clear!

    rtp = Tataru::ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    rtp.add_resource_desc(:string_joiner, StringJoinerResourceDesc)

    ttr = Tataru::Taru.new(rtp) do
      r1 = resource :file, 'f1' do
        name 'something1.txt'
        contents 'meow'
      end

      r2 = resource :file, 'f2' do
        name 'something2.txt'
        contents 'woof'
      end

      sj = resource :string_joiner, 'joiner' do
        strings [r1.created_at, r2.created_at]
      end

      resource :file, 'cdates' do
        name 'creationdates.txt'
        contents sj.result
      end
    end

    travel_to Time.new(2012, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        break unless ttr.step
      end
    end

    expect(ttr.error).to be_nil

    expect(ttr.oplog).to eq [
      {operation: 'CREATE', resource: 'f1'},
      {operation: 'CREATE', resource: 'f2'},
      {operation: 'CHECK_CREATE', resource: 'f1'},
      {operation: 'CHECK_CREATE', resource: 'f2'},
      {operation: 'CREATE', resource: 'joiner'},
      {operation: 'CHECK_CREATE', resource: 'joiner'},
      {operation: 'CREATE', resource: 'cdates'},
      {operation: 'CHECK_CREATE', resource: 'cdates'}
    ]

    expect(TestEnvironment.instance.file('something1.txt')).to include(
      contents: 'meow'
    )

    expect(TestEnvironment.instance.file('something2.txt')).to include(
      contents: 'woof'
    )

    expect(TestEnvironment.instance.file('creationdates.txt')).to include(
      contents: "2012-01-01 00:00:00 UTC\n2012-01-01 00:00:00 UTC"
    )

    expect(ttr.state).to eq(
      'f1' => {
        name: 'something1.txt',
        desc: 'TestFileResourceDesc',
        dependencies: []
      },
      'f2' => {
        name: 'something2.txt',
        desc: 'TestFileResourceDesc',
        dependencies: []
      },
      'joiner' => {
        name: "2012-01-01 00:00:00 UTC\n2012-01-01 00:00:00 UTC",
        desc: 'StringJoinerResourceDesc',
        dependencies: ['f1', 'f2']
      },
      'cdates' => {
        name: 'creationdates.txt',
        desc: 'TestFileResourceDesc',
        dependencies: ['joiner']
      }
    )
  end

  it 'breaks before deleting an overlapping resource but can continue' do
    TestEnvironment.instance.clear!

    TestEnvironment.instance.servers = [
      {
        size: 'A',
        created_at: "2010-01-01 00:00:00 UTC"
      }
    ]

    TestEnvironment.instance.ip_addresses = {
      '2.3.4.2' => 'server0'
    }

    rtp = Tataru::ResourceTypePool.new
    rtp.add_resource_desc(:ip_address, TestIpAddressResourceDesc)
    rtp.add_resource_desc(:server, TestServerResourceDesc)
    remote_ids = {
      'serv' => {
        name: 'server0',
        desc: 'TestServerResourceDesc',
        dependencies: []
      },
      'ip' => {
        name: '2.3.4.2',
        desc: 'TestIpAddressResourceDesc',
        dependencies: ['serv']
      }
    }

    ttr = Tataru::Taru.new(rtp, remote_ids) do
      s = resource :server, 'serv' do
        size 'B'
      end

      resource :ip_address, 'ip' do
        server_id s
      end
    end

    allow_any_instance_of(TestIpAddressResource).to receive(:update_complete?) { raise 'Stop!' }

    travel_to Time.new(2015, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        break unless ttr.step
      end
    end

    expect(ttr.error).to be_a RuntimeError

    expect(ttr.oplog).to eq [
      {operation: 'READ', resource: 'serv'},
      {operation: 'RESCMP', resource: 'serv'},
      {operation: 'MARK_DELETABLE', resource: 'serv'},
      {operation: 'CREATE', resource: 'serv'},
      {operation: 'CHECK_CREATE', resource: 'serv'},
      {operation: 'READ', resource: 'ip'},
      {operation: 'RESCMP', resource: 'ip'},
      {operation: 'UPDATE', resource: 'ip'},
      {operation: 'CHECK_UPDATE', resource: 'ip'}
    ]

    expect(TestEnvironment.instance.servers).to eq [
      {
        size: 'A',
        created_at: "2010-01-01 00:00:00 UTC"
      },
      {
        size: 'B',
        created_at: "2015-01-01 00:00:00 UTC"
      }
    ]

    expect(TestEnvironment.instance.ip_addresses).to eq(
      '2.3.4.2' => 'server1'
    )

    expect(ttr.state).to eq(
      '_deletable_serv' => {
        name: 'server0',
        desc: 'TestServerResourceDesc',
        dependencies: []
      },
      'serv' => {
        name: 'server1',
        desc: 'TestServerResourceDesc',
        dependencies: []
      },
      'ip' => {
        name: '2.3.4.2',
        desc: 'TestIpAddressResourceDesc',
        dependencies: ['serv']
      }
    )

    ttr2 = Tataru::Taru.new(rtp, ttr.state) do
      s = resource :server, 'serv' do
        size 'B'
      end

      resource :ip_address, 'ip' do
        server_id s
      end
    end

    travel_to Time.new(2015, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        break unless ttr2.step
      end
    end

    expect(ttr2.error).to be_nil

    expect(ttr2.oplog).to eq [
      {operation: 'READ', resource: 'serv'},
      {operation: 'RESCMP', resource: 'serv'},
      {operation: 'READ', resource: 'ip'},
      {operation: 'RESCMP', resource: 'ip'},
      {operation: 'DELETE', resource: '_deletable_serv'},
      {operation: 'CHECK_DELETE', resource: '_deletable_serv'}
    ]

    expect(ttr2.state).to eq(
      'serv' => {
        name: 'server1',
        desc: 'TestServerResourceDesc',
        dependencies: []
      },
      'ip' => {
        name: '2.3.4.2',
        desc: 'TestIpAddressResourceDesc',
        dependencies: ['serv']
      }
    )
  end
end
