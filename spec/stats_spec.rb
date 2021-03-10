require 'spec_helper'

require './lib/stats'

describe Stats do

  context 'clustered stats' do
    let(:stats) { Stats.new({"started_at"=>"2019-07-14T14:32:56Z", "workers"=>4, "phase"=>0, "booted_workers"=>4, "old_workers"=>0, "worker_status"=>[{"started_at"=>"2019-07-14T14:32:56Z", "pid"=>28909, "index"=>0, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{"backlog"=>0, "running"=>4, "pool_capacity"=>0, "max_threads"=>4}}, {"started_at"=>"2019-07-14T14:32:56Z", "pid"=>28911, "index"=>1, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{"backlog"=>0, "running"=>4, "pool_capacity"=>0, "max_threads"=>4}}, {"started_at"=>"2019-07-14T14:32:56Z", "pid"=>28917, "index"=>2, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{"backlog"=>0, "running"=>4, "pool_capacity"=>1, "max_threads"=>4}}, {"started_at"=>"2019-07-14T14:32:56Z", "pid"=>28921, "index"=>3, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{"backlog"=>0, "running"=>2, "pool_capacity"=>3, "max_threads"=>4}}]}) }

     it 'returns uptime 0 for older version of puma' do
       stats = Stats.new({"workers"=>4, "phase"=>0, "booted_workers"=>4, "old_workers"=>0, "worker_status"=>[{"pid"=>28909, "index"=>0, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{"backlog"=>0, "running"=>4, "pool_capacity"=>0, "max_threads"=>4}}, {"pid"=>28911, "index"=>1, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{"backlog"=>0, "running"=>4, "pool_capacity"=>0, "max_threads"=>4}}, {"pid"=>28917, "index"=>2, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{"backlog"=>0, "running"=>4, "pool_capacity"=>1, "max_threads"=>4}}, {"pid"=>28921, "index"=>3, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{"backlog"=>0, "running"=>4, "pool_capacity"=>2, "max_threads"=>4}}]})
       expect(stats.uptime).to eq(0)
       expect(stats.workers.map { |wstats| wstats.uptime }).to eq([0, 0, 0, 0])
     end

     it 'gives workers' do
       expect(stats.workers.count).to eq(4)
     end

     it 'gives running threads' do
       expect(stats.running_threads).to eq(12)
     end

     it 'gives total threads' do
       expect(stats.total_threads).to eq(16)
     end

     it 'master is not marked as booting' do
       expect(stats.booting?).to eq(false)
     end

     it 'master process is marked as booting' do
       stats = Stats.new({"workers"=>4, "phase"=>0, "booted_workers"=>4, "old_workers"=>0, "worker_status"=>[{"pid"=>28909, "index"=>0, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{}}, {"pid"=>28911, "index"=>1, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{}}]})
       expect(stats.booting?).to eq(true)
     end

     it 'gives the number of requests' do
       stats = Stats.new({"workers"=>4, "phase"=>0, "booted_workers"=>4, "old_workers"=>0, "worker_status"=>[{"pid"=>28909, "index"=>0, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{"requests_count" => 150}}, {"pid"=>28911, "index"=>1, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{"backlog"=>0, "running"=>4, "pool_capacity"=>0, "max_threads"=>4, "requests_count" => 300}}]})
       expect(stats.requests_count).to eq(450)
     end

     context 'workers' do
       it 'gives running threads first worker' do
         expect(stats.workers.first.running_threads).to eq(4)
       end

       it 'gives total threads first worker' do
         expect(stats.workers.first.total_threads).to eq(4)
       end

       it 'gives total threads last worker' do
         expect(stats.workers.last.total_threads).to eq(4)
       end

       it 'gives running threads last worker' do
         expect(stats.workers.last.running_threads).to eq(1)
       end

       it 'can mark worker as killed' do
         worker = stats.workers.first
         expect {
           worker.killed = true
         }.to change(worker, :killed?).from(false).to(true)
       end

       it 'worker is marked as booting' do
         stats = Stats.new({"workers"=>4, "phase"=>0, "booted_workers"=>4, "old_workers"=>0, "worker_status"=>[{"pid"=>28909, "index"=>0, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{}}, {"pid"=>28911, "index"=>1, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{"backlog"=>0, "running"=>4, "pool_capacity"=>0, "max_threads"=>4}}]})
         worker = stats.workers.first
         expect(worker.booting?).to eq(true)
       end

       it 'gives the number of requests' do
         stats = Stats.new({"workers"=>4, "phase"=>0, "booted_workers"=>4, "old_workers"=>0, "worker_status"=>[{"pid"=>28909, "index"=>0, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{"requests_count" => 150}}, {"pid"=>28911, "index"=>1, "phase"=>0, "booted"=>true, "last_checkin"=>"2019-07-14T14:33:54Z", "last_status"=>{"backlog"=>0, "running"=>4, "pool_capacity"=>0, "max_threads"=>4, "requests_count" => 300}}]})
         worker = stats.workers.first
         expect(worker.requests_count).to eq(150)
       end
     end
  end

  context 'single stats' do
    let(:stats) { Stats.new({"started_at"=>"2019-07-14T15:07:15Z", "backlog"=>0, "running"=>4, "pool_capacity"=>2, "max_threads"=>4, "requests_count"=>150}) }

     it 'returns uptime 0 for older version of puma' do
       stats = Stats.new({"backlog"=>0, "running"=>4, "pool_capacity"=>2, "max_threads"=>4})
       expect(stats.uptime).to eq(0)
     end

     it 'gives workers' do
       expect(stats.workers.count).to eq(1)
     end

     it 'gives running threads' do
       expect(stats.running_threads).to eq(2)
     end

     it 'gives total threads' do
       expect(stats.total_threads).to eq(4)
     end

     it 'gives the number of requests' do
       expect(stats.requests_count).to eq(150)
     end

     context 'workers' do
       it 'gives running threads' do
         expect(stats.workers.first.running_threads).to eq(2)
       end

       it 'gives total threads' do
         expect(stats.workers.first.total_threads).to eq(4)
       end

       it 'gives the number of requests' do
         expect(stats.workers.first.requests_count).to eq(150)
       end
     end
  end

end
