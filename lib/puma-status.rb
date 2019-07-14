require_relative './helpers'
require_relative './core.rb'

def run
  debug "puma-status"
  state_file_path = ARGV[0]
  debug "State file: #{state_file_path}"
  display_stats(get_stats(state_file_path))
end
