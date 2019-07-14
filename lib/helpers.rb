require 'colorize'

def debug(str)
  puts str if ENV.key?('DEBUG')
end

def color(critical, warn, value, str)
  return str if ENV.key?('NO_COLOR')

  color = if value >= critical
            :red
          elsif value < critical && value >= warn
            :yellow
          else
            :green
          end
  str.to_s.colorize(color)
end

def asciiThreadLoad(idx, total)
  full = "█"
  empty= "░"

  "#{idx}[#{full*idx}#{empty*(total-idx)}]#{total}"
end

def seconds_to_human(seconds)

  #=>  0m 0s
  #=> 59m59s
  #=>  1h 0m
  #=> 23h59m
  #=>  1d 0h
  #=>    24d
  
  if seconds < 60*60
    "#{(seconds/60).to_s.rjust(2, ' ')}m#{(seconds%60).to_s.rjust(2, ' ')}s"
  elsif seconds >= 60*60*1 && seconds < 60*60*24
    "#{(seconds/(60*60*1)).to_s.rjust(2, ' ')}h#{((seconds%(60*60*1))/60).to_s.rjust(2, ' ')}m"
  elsif seconds > 60*60*24 && seconds < 60*60*24*10
    "#{(seconds/(60*60*24)).to_s.rjust(2, ' ')}d#{((seconds%(60*60*24))/(60*60*1)).to_s.rjust(2, ' ')}h"
  else
    "#{seconds/(60*60*24)}d".rjust(6, ' ')
  end
end
