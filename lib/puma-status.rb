require_relative './helpers'
require_relative './core.rb'
require 'parallel'

def run
  run_argv(ARGV)
end

def run_argv(argv)
  debug "puma-status"

  if argv.count < 1
    puts "Call with:"
    puts "\tpuma-status path/to/puma.state"
    exit -1
  end

  errors = []

  outputs = Parallel.map(argv, in_threads: argv.count) do |state_file_path|
    begin
      debug "State file: #{state_file_path}"
      format_stats(get_stats(state_file_path))
    rescue Errno::ENOENT => e
      if e.message =~ /#{state_file_path}/
        errors << "#{yellow(state_file_path)} doesn't exist"
      elsif e.message =~ /connect\(2\) for [^\/]/
        errors << "#{yellow("Relative Unix socket")}: the Unix socket of the control app has a relative path. Please, ensure you are running from the same folder as puma."
      else
        errors << "#{red(state_file_path)} an unhandled error occured: #{e.inspect}"
      end
      nil
    rescue Errno::EISDIR => e
      if e.message =~ /#{state_file_path}/
        errors << "#{yellow(state_file_path)} isn't a state file"
      else
        errors << "#{red(state_file_path)} an unhandled error occured: #{e.inspect}"
      end
      nil
    rescue => e
      errors << "#{red(state_file_path)} an unhandled error occured: #{e.inspect}"
      nil
    end
  end

  outputs.compact.each { |output| puts output }

  if errors.any?
    puts ""
    errors.each { |error| puts error }
  end
end
