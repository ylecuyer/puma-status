require 'rainbow'

def debug(str)
  puts str if ENV.key?('DEBUG')
end

def yellow(str)
  rainbow(str, :yellow)
end

def red(str)
  rainbow(str, :red)
end

def rainbow(str, color_name)
  return str if ENV.key?('NO_COLOR')
  Rainbow(str.to_s).send(color_name)
end

def color(critical, warn, value, str = nil)
  str = value unless str
  color_level = if value >= critical
            :red
          elsif value < critical && value >= warn
            :yellow
          else
            :green
          end
  rainbow(str, color_level)
end

def asciiThreadLoad(running, spawned, total)
  full = "█"
  half= "░"
  empty = " "

  full_count = running
  half_count = [spawned - running, 0].max
  empty_count = total - half_count - full_count

  "#{running}[#{full*full_count}#{half*half_count}#{empty*empty_count}]#{total}"
end

def seconds_to_human(seconds)

  #=>  0m 0s
  #=> 59m59s
  #=>  1h 0m
  #=> 23h59m
  #=>  1d 0h
  #=>    24d

  if seconds <= 0
    "--m--s"
  elsif seconds < 60*60
    "#{(seconds/60).to_s.rjust(2, ' ')}m#{(seconds%60).to_s.rjust(2, ' ')}s"
  elsif seconds >= 60*60*1 && seconds < 60*60*24
    "#{(seconds/(60*60*1)).to_s.rjust(2, ' ')}h#{((seconds%(60*60*1))/60).to_s.rjust(2, ' ')}m"
  elsif seconds > 60*60*24 && seconds < 60*60*24*10
    "#{(seconds/(60*60*24)).to_s.rjust(2, ' ')}d#{((seconds%(60*60*24))/(60*60*1)).to_s.rjust(2, ' ')}h"
  else
    "#{seconds/(60*60*24)}d".rjust(6, ' ')
  end
end
