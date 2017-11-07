#!/usr/bin/env ruby
require "./aws-lib.rb"
require "./azure-lib.rb"
require "./ssh-lib2.rb"
require "./pc-lib2.rb"
require "time"
require "yaml"

def containerID(s)
  s.split(' ')[0]
end

courses = YAML.load_file ARGV[0]

def logsPCMac(host)
  if pcRunning?(host)
    puts "#{host}"
    puts '='*("#{host}".length)
    for s in pcGetContainers(host) do
      puts "#{host}-#{containerID(s)}"
      puts pcGetLogs(host,containerID(s))
    end
  end
end

for host in courses.keys do
  host = host.downcase
  if ['pc','mac','localhost','macppt','macntp'].include? host 
    logsPCMac(host)
  elsif host.include? 'aws'
    i = host.scan(/\d+/)[0]
    puts "aws#{i}"
    puts "="*("aws#{i}".length)
    for s in awsGetContainers(i) do
        puts "aws#{i}-#{containerID(s)}"
        puts awsGetLogs(i,containerID(s))
    end
  elsif host.include? 'azure'
    i = host.scan(/\d+/)[0]
    puts "azure#{i}"
    puts "="*("azure#{i}".length)
    for s in azureGetContainers(i) do
      puts "azure#{i}-#{containerID(s)}"
      puts azureGetLogs(i,containerID(s))
    end
  end
end

exit
# aws

# azure
for i in azureGetRunning() do

end

# pc,mac
def logsPCMac(host)
  if pcRunning?(host)
    puts "#{host}"
    puts '='*("#{host}".length)
    for s in pcGetContainers(host) do
      puts "{host}-#{containerID(s)}"
      puts pcGetLogs(host,containerID(s))
    end
  end
end
# logsPCMac('localhost')
logsPCMac('pc')
logsPCMac('mac')
logsPCMac('macppt')
logsPCMac('macntp')

