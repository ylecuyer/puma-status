require 'yaml'
require 'json'
require 'net_x/http_unix'
require 'openssl'
require 'time'
require 'open3'
require_relative 'stats'

def get_stats(state_file_path)
  puma_state = YAML.load_file(state_file_path)

  uri = URI.parse(puma_state["control_url"])

  address = if uri.scheme =~ /unix/i
              [uri.scheme, '://', uri.host, uri.path].join
            else
              [uri.host, uri.path].join
            end

  client = NetX::HTTPUnix.new(address, uri.port)

  if uri.scheme =~ /ssl/i
    client.use_ssl = true
    client.verify_mode = OpenSSL::SSL::VERIFY_NONE if ENV['SSL_NO_VERIFY'] == '1'
  end

  req = Net::HTTP::Get.new("/stats?token=#{puma_state["control_auth_token"]}")
  resp = client.request(req)
  raw_stats = JSON.parse(resp.body)
  debug raw_stats
  stats = Stats.new(raw_stats)

  hydrate_stats(stats, puma_state, state_file_path)
end

def get_memory_from_top(raw_memory)
  case raw_memory[-1].downcase
  when 'g'
    (raw_memory[0...-1].to_f*1024).to_i
  when 'm'
    raw_memory[0...-1].to_i
  else
    raw_memory.to_i/1024
  end
end

PID_COLUMN = 0
MEM_COLUMN = 5
CPU_COLUMN = 8
OPEN3_STDOUT = 1

def get_top_stats(pids)
  pids.each_slice(19).inject({}) do |res, pids19|
    top_result = Open3.popen3({ 'LC_ALL' => 'C' }, "top -b -n 1 -p #{pids19.map(&:to_i).join(',')}")[OPEN3_STDOUT].read
    top_result.split("\n").last(pids19.length).map { |row| r = row.split(' '); [r[PID_COLUMN].to_i, get_memory_from_top(r[MEM_COLUMN]), r[CPU_COLUMN].to_f] }
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
  master_line = "#{stats.pid} (#{stats.state_file_path})"
  master_line += " Version: #{stats.version} |" if stats.version
  master_line += " Uptime: #{seconds_to_human(stats.uptime)}"
  master_line += " | Phase: #{stats.phase}" if stats.phase

  if stats.booting?
    master_line += " #{yellow("booting")}"
  else
    master_line += " | Load: #{color(75, 50, stats.load, asciiThreadLoad(stats.running_threads, stats.spawned_threads, stats.max_threads))}"
    master_line += " | Req: #{stats.requests_count}" if stats.requests_count
  end

  output = [master_line] + stats.workers.map do |wstats|
    worker_line = " └ #{wstats.pid.to_s.rjust(5, ' ')} CPU: #{color(75, 50, wstats.pcpu, wstats.pcpu.to_s.rjust(5, ' '))}% Mem: #{color(1000, 750, wstats.mem, wstats.mem.to_s.rjust(4, ' '))} MB Uptime: #{seconds_to_human(wstats.uptime)}"

    if wstats.booting?
      worker_line += " #{yellow("booting")}"
    elsif wstats.killed?
      worker_line += " #{red("killed")}"
    else
      worker_line += " | Load: #{color(75, 50, wstats.load, asciiThreadLoad(wstats.running_threads, wstats.spawned_threads, wstats.max_threads))}"
      worker_line += " | Phase: #{red(wstats.phase)}" if wstats.phase != stats.phase
      worker_line += " | Req: #{wstats.requests_count}" if wstats.requests_count
      worker_line += " Queue: #{red(wstats.backlog.to_s)}" if wstats.backlog > 0
      worker_line += " Last checkin: #{red(wstats.last_checkin)}" if wstats.last_checkin >= 10
    end

    worker_line
  end

  output.join("\n")
end
