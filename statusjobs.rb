#!/usr/bin/env ruby
require "./aws-lib.rb"
require "./azure-lib.rb"
require "time"

def containerID(s)
  s.split(' ')[0]
end

# aws
for i in awsGetRunning() do
  puts "aws#{i} running"
  puts
  for s in awsGetContainers(i) do
    puts "Container #{containerID(s)}"
    puts awsGetLogs(i,containerID(s))
    puts '-'*40
    puts
  end
  puts '='*60
  puts
end

# azure
for i in azureGetRunning() do
  puts "azure#{i} running"
  puts
  for s in azureGetContainers(i) do
    puts "Container #{containerID(s)}"
    puts azureGetLogs(i,containerID(s))
    puts '-'*40
    puts
  end
  puts '='*60
  puts
end
