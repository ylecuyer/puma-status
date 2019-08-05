require 'yaml'
require 'json'
require 'net_x/http_unix'
require 'time'
require_relative 'stats'

def get_stats(state_file_path)
  puma_state = YAML.load_file(state_file_path)

  client = NetX::HTTPUnix.new(puma_state["control_url"])
  req = Net::HTTP::Get.new("/stats?token=#{puma_state["control_auth_token"]}")
  resp = client.request(req)
  raw_stats = JSON.parse(resp.body)
  debug raw_stats
  stats = Stats.new(raw_stats)

  hydrate_stats(stats, puma_state, state_file_path)
end

def get_top_stats(pids)
  pids.each_slice(19).inject({}) do |res, pids19|
    top_result = `top -b -n 1 -p #{pids19.join(',')} | tail -n #{pids19.length}`
    top_result.split("\n").map { |row| r = row.split(' '); [r[0].to_i, r[5].to_i/1024, r[8].to_f] }
      .inject(res) { |hash, row| hash[row[0]] = { mem: row[1], pcpu: row[2] }; hash }
    res
  end
end

def hydrate_stats(stats, puma_state, state_file_path)
  stats.pid = puma_state['pid']
  stats.state_file_path = state_file_path

  workers_pids = stats.workers.map(&:pid)

  top_stats = get_top_stats(workers_pids)

  stats.tap do |s|
    stats.workers.map do |wstats|
      wstats.mem = top_stats[wstats.pid][:mem]
      wstats.pcpu = top_stats[wstats.pid][:pcpu]
    end
  end
end

def display_stats(stats)
  puts "#{stats.pid} (#{stats.state_file_path}) Uptime: #{seconds_to_human(stats.uptime)} | Load: #{color(75, 50, stats.load, asciiThreadLoad(stats.running_threads, stats.total_threads))}"

  stats.workers.each do |wstats|
    worker_line = " └ #{wstats.pid.to_s.rjust(5, ' ')} CPU: #{color(75, 50, wstats.pcpu, wstats.pcpu.to_s.rjust(5, ' '))}% Mem: #{color(1000, 750, wstats.mem, wstats.mem.to_s.rjust(4, ' '))} MB Uptime: #{seconds_to_human(wstats.uptime)} | Load: #{color(75, 50, wstats.load, asciiThreadLoad(wstats.running_threads, wstats.total_threads))}"
    worker_line += " #{("Queue: " + wstats.backlog.to_s).colorize(:red)}" if wstats.backlog > 0
    worker_line += " Last checkin: #{wstats.last_checkin}" if wstats.last_checkin >= 10

    puts worker_line
  end
end
