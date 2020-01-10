require_relative './helpers'
require_relative './core.rb'

def run
  debug "puma-status"

  if ARGV.count < 1
    puts "Call with:"
    puts "\tpuma-status path/to/puma.state"
    exit -1
  end

  ARGV.each do |state_file_path|
    debug "State file: #{state_file_path}"
    display_stats(get_stats(state_file_path))
  end
end
