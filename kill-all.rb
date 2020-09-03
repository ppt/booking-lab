#!/usr/bin/env ruby

s = `ps -ef | grep booking`
lines = s.split("\n")
p lines.length
lines.each { |l| 
  proc = l.split()[1]
  # p l
  # p l.split()[1]
  `kill #{proc}`
}
puts 'END'