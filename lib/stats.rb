class Stats

  class Worker
    def initialize(wstats)
      @wstats = wstats
    end

    def pid
      @wstats['pid']
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

    def running
      @wstats.dig('last_status', 'running') || @wstats['running'] || 0
    end
    alias :total_threads :running

    def pool_capacity
      @wstats.dig('last_status', 'pool_capacity') || @wstats['pool_capacity'] || 0
    end

    def running_threads
      running - pool_capacity
    end

    def load
      running_threads/total_threads.to_f*100
    end

    def uptime
      (Time.now - Time.parse(@wstats['started_at'])).to_i
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
    (@stats['worker_status'] || [@stats]).map { |wstats| Worker.new(wstats) }
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
    (Time.now - Time.parse(@stats['started_at'])).to_i
  end

  def total_threads
    workers.reduce(0) { |total, wstats| total + wstats.running }
  end

  def running_threads
    workers.reduce(0) { |total, wstats| total + (wstats.running - wstats.pool_capacity) }
  end

  def running
    @stats['running'] || 0
  end

  def pool_capacity
    @stats['pool_capacity'] || 0
  end

  def load
    running_threads/total_threads.to_f*100
  end
end
