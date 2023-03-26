require_relative './helpers'
require_relative './core.rb'
require 'parallel'

def run
  debug "puma-status"

  if ARGV.count < 1
    puts "Call with:"
    puts "\tpuma-status path/to/puma.state"
    exit -1
  end

  errors = []
  
  outputs = Parallel.map(ARGV, in_threads: ARGV.count) do |state_file_path|
    begin
      debug "State file: #{state_file_path}"
      format_stats(get_stats(state_file_path))
    rescue Errno::ENOENT => e
      if e.message =~ /#{state_file_path}/
        errors << "#{yellow(state_file_path)} doesn't exists"
      elsif e.message =~ /connect\(2\) for [^\/]/
        errors << "#{yellow("Relative Unix socket")}: the Unix socket of the control app has a relative path. Please, ensure you are running from the same folder has puma."
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
