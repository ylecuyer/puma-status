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
      wstats.mem = top_stats.dig(wstats.pid, :mem) || 0
      wstats.pcpu = top_stats.dig(wstats.pid, :pcpu) || 0
      wstats.killed = !top_stats.key?(wstats.pid) || (wstats.mem <=0 && wstats.pcpu <= 0)
    end
  end
end

def format_stats(stats)
  master_line = "#{stats.pid} (#{stats.state_file_path}) Uptime: #{seconds_to_human(stats.uptime)} "
  master_line += "| Phase: #{stats.phase} " if stats.phase

  if stats.booting?
    master_line += warn("booting")
  else
    master_line += "| Load: #{color(75, 50, stats.load, asciiThreadLoad(stats.running_threads, stats.max_threads))}"
  end

  output = [master_line] + stats.workers.map do |wstats|
    worker_line = " └ #{wstats.pid.to_s.rjust(5, ' ')} CPU: #{color(75, 50, wstats.pcpu, wstats.pcpu.to_s.rjust(5, ' '))}% Mem: #{color(1000, 750, wstats.mem, wstats.mem.to_s.rjust(4, ' '))} MB Uptime: #{seconds_to_human(wstats.uptime)}"

    if wstats.booting?
      worker_line += " #{warn("booting")}"
    elsif wstats.killed?
      worker_line += " #{error("killed")}"
    else
      worker_line += " | Load: #{color(75, 50, wstats.load, asciiThreadLoad(wstats.running_threads, wstats.max_threads))}"
      worker_line += " | Req: #{wstats.requests_count}" if wstats.requests_count
      worker_line += " Phase: #{error(wstats.phase)}" if wstats.phase != stats.phase
      worker_line += " Queue: #{error(wstats.backlog.to_s)}" if wstats.backlog > 0
      worker_line += " Last checkin: #{error(wstats.last_checkin)}" if wstats.last_checkin >= 10
    end

    worker_line
  end

  output.join("\n")
end
