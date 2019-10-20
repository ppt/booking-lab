#!/usr/bin/env ruby
require "./aws-lib.rb"
require "./ssh-lib2.rb"
require "time"

def containerID(s)
  s.split(' ')[0]
end

# aws
for i in awsGetRunning() do
  puts "aws#{i} running"
  for s in awsGetContainers(i) do
    File.open("#{$dir_name}/aws#{i}-#{containerID(s)}", 'w') { |file| file.write(awsGetLogs(i,containerID(s))) }
    puts "aws#{i}-#{containerID(s)}" 
    puts awsGetLogs(i,containerID(s))
  end
end
