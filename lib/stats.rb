class Stats

  class Worker
    def initialize(wstats)
      @wstats = wstats
    end

    def pid
      @wstats['pid']
    end

    def killed=(killed)
      @wstats['killed'] = killed
    end

    def killed?
      !!@wstats['killed']
    end

    def mem=(mem)
      @wstats['mem'] = mem
    end

    def mem
      @wstats['mem']
    end

    def pcpu=(pcpu)
      @wstats['pcpu'] = pcpu
    end

    def pcpu
      @wstats['pcpu']
    end

    def booting?
      @wstats.key?('last_status') && @wstats['last_status'].empty?
    end

    def running
      @wstats.dig('last_status', 'running') || @wstats['running'] || 0
    end
    alias :total_threads :running

    def max_threads
      @wstats.dig('last_status', 'max_threads') || @wstats['max_threads'] || 0
    end

    def pool_capacity
      @wstats.dig('last_status', 'pool_capacity') || @wstats['pool_capacity'] || 0
    end

    def running_threads
      max_threads - pool_capacity
    end

    def phase
      @wstats['phase']
    end

    def load
      running_threads/total_threads.to_f*100
    end

    def uptime
      return 0 unless @wstats.key?('started_at')
      (Time.now - Time.parse(@wstats['started_at'])).to_i
    end

    def requests_count
      @wstats.dig('last_status', 'requests_count') || @wstats['requests_count']
    end

    def backlog
      @wstats.dig('last_status', 'backlog') || 0
    end

    def last_checkin
      (Time.now - Time.parse(@wstats['last_checkin'])).round
    rescue
      0
    end
  end

  def initialize(stats)
    @stats = stats
  end

  def workers
    @workers ||= (@stats['worker_status'] || [@stats]).map { |wstats| Worker.new(wstats) }
  end

  def pid=(pid)
    @stats['pid'] = pid
  end

  def pid
    @stats['pid']
  end

  def state_file_path=(state_file_path)
    @stats['state_file_path'] = state_file_path
  end

  def state_file_path
    @stats['state_file_path']
  end

  def uptime
    return 0 unless @stats.key?('started_at')
    (Time.now - Time.parse(@stats['started_at'])).to_i
  end

  def booting?
    workers.all?(&:booting?)
  end

  def total_threads
    workers.reduce(0) { |total, wstats| total + wstats.max_threads }
  end

  def running_threads
    workers.reduce(0) { |total, wstats| total + wstats.running_threads }
  end

  def max_threads
    workers.reduce(0) { |total, wstats| total + wstats.max_threads }
  end

  def requests_count
    workers_with_requests_count = workers.select(&:requests_count)
    return if workers_with_requests_count.none?
    workers_with_requests_count.reduce(0) { |total, wstats| total + wstats.requests_count }
  end

  def running
    @stats['running'] || 0
  end

  def pool_capacity
    @stats['pool_capacity'] || 0
  end

  def phase
    @stats['phase']
  end

  def load
    running_threads/total_threads.to_f*100
  end
end
