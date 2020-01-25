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
  
  outputs = Parallel.map(ARGV, in_threads: ARGV.count) do |state_file_path|
    debug "State file: #{state_file_path}"
    format_stats(get_stats(state_file_path))
  end

  outputs.each { |output| puts output }
end
