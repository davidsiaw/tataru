# frozen_string_literal: true

require 'tataru'

describe Tataru::Quest do
  it 'builds one resource' do
    TestEnvironment.instance.clear!

    rtp = Tataru::ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    ttr = Tataru::Quest.new(rtp)
    ttr.construct do
      resource :file, 'file' do
        name 'something1.txt'
        contents '123'
      end
    end
    ih = Tataru::InstructionHash.new(ttr.instr_hash)
    runner = Tataru::Runner.new(ih.instruction_list)
    travel_to Time.new(2011, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end
    expect(runner.memory.error).to be_nil
    expect(TestEnvironment.instance.files).to eq(
      'something1.txt' => {
        name: 'something1.txt',
        contents: '123',
        created_at: "2011-01-01 00:00:00 UTC",
        updated_at: "2011-01-01 00:00:00 UTC"
      }
    )

    expect(runner.memory.hash[:remote_ids]['file']).to eq 'something1.txt'
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

    ttr = Tataru::Quest.new(rtp, remote_ids)
    ttr.construct do
      resource :file, 'file2' do
        name 'something2.txt'
        contents '123'
      end
    end

    ih = Tataru::InstructionHash.new(ttr.instr_hash)
    runner = Tataru::Runner.new(ih.instruction_list)

    travel_to Time.new(2011, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end
    expect(runner.memory.error).to be_nil
    expect(TestEnvironment.instance.files).to eq(
      'something2.txt' => {
        name: 'something2.txt',
        contents: '123',
        created_at: "2011-01-01 00:00:00 UTC",
        updated_at: "2011-01-01 00:00:00 UTC"
      }
    )

    expect(runner.memory.hash[:remote_ids]['file2']).to eq 'something2.txt'
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

    ttr = Tataru::Quest.new(rtp, remote_ids)
    ttr.construct do
      s = resource :server, 'serv' do
        size 'SMOL'
      end

      resource :file, 'file1' do
        name 'something2.txt'
        contents s.created_at
      end
    end

    ih = Tataru::InstructionHash.new(ttr.instr_hash)
    runner = Tataru::Runner.new(ih.instruction_list)

    travel_to Time.new(2015, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end

    expect(runner.memory.error).to be_nil
    expect(TestEnvironment.instance.servers).to eq [
      nil,
      {
        size: 'SMOL',
        created_at: "2015-01-01 00:00:00 UTC"
      }
    ]

    expect(runner.memory.hash[:remote_ids]['serv']).to eq 'server1'
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

    ttr = Tataru::Quest.new(rtp, remote_ids)
    ttr.construct do
      resource :file, 'file' do
        name 'ddd.txt'
        contents '123'
      end
    end

    ih = Tataru::InstructionHash.new(ttr.instr_hash)
    runner = Tataru::Runner.new(ih.instruction_list)

    travel_to Time.new(2011, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end

    expect(runner.memory.error).to be_nil
    expect(TestEnvironment.instance.files).to eq(
      'ddd.txt' => {
        name: 'ddd.txt',
        contents: '123',
        created_at: "2010-01-01 00:00:00 UTC",
        updated_at: "2011-01-01 00:00:00 UTC"
      }
    )

    expect(runner.memory.hash[:remote_ids]['file']).to eq 'ddd.txt'
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

    ttr = Tataru::Quest.new(rtp, remote_ids)
    ttr.construct do
      resource :file, 'file' do
        name 'fff.txt'
        contents '123'
      end
    end

    ih = Tataru::InstructionHash.new(ttr.instr_hash)
    runner = Tataru::Runner.new(ih.instruction_list)

    travel_to Time.new(2011, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end
    expect(runner.memory.error).to be_nil
    expect(TestEnvironment.instance.files).to eq(
      'fff.txt' => {
        name: 'fff.txt',
        contents: '123',
        created_at: "2011-01-01 00:00:00 UTC",
        updated_at: "2011-01-01 00:00:00 UTC"
      }
    )

    expect(runner.memory.hash[:remote_ids]['file']).to eq 'fff.txt'
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

    ttr = Tataru::Quest.new(rtp, remote_ids)
    ttr.construct do
      s = resource :server, 'serv' do
        size 'B'
      end

      resource :ip_address, 'ip' do
        server_id s
      end
    end

    ih = Tataru::InstructionHash.new(ttr.instr_hash)
    runner = Tataru::Runner.new(ih.instruction_list)

    travel_to Time.new(2015, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end

    #puts runner.memory.error.backtrace.to_yaml

    expect(runner.memory.error).to be_nil
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

    expect(runner.memory.hash[:remote_ids]['serv']).to eq 'server1'
  end

  it 'builds multiple resources' do
    TestEnvironment.instance.clear!

    rtp = Tataru::ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    rtp.add_resource_desc(:string_joiner, StringJoinerResourceDesc)

    ttr = Tataru::Quest.new(rtp)
    ttr.construct do
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
    ih = Tataru::InstructionHash.new(ttr.instr_hash)
    runner = Tataru::Runner.new(ih.instruction_list)

    #puts ttr.instr_hash.to_yaml
    travel_to Time.new(2012, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end

    expect(runner.memory.error).to be_nil

    expect(TestEnvironment.instance.file('something1.txt')).to include(
      contents: 'meow'
    )
    expect(TestEnvironment.instance.file('something2.txt')).to include(
      contents: 'woof'
    )
    expect(TestEnvironment.instance.file('creationdates.txt')).to include(
      contents: "2012-01-01 00:00:00 UTC\n2012-01-01 00:00:00 UTC"
    )
    expect(runner.memory.hash[:remote_ids]['f1']).to eq 'something1.txt'
    expect(runner.memory.hash[:remote_ids]['f2']).to eq 'something2.txt'
    expect(runner.memory.hash[:remote_ids]['cdates']).to eq 'creationdates.txt'
  end
end
