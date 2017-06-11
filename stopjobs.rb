#!/usr/bin/env ruby
require "./aws-lib.rb"
require "./azure-lib.rb"
require "time"

def containerID(s)
  s.split(' ')[0]
end

if ARGV.empty?
  sleep(Time.parse("22:30") - Time.now)
end

dir_name = "logs/#{Time.now.strftime("%d-%m-%Y")}"
`mkdir logs`
`mkdir #{dir_name}`

def d_stop(host)
  if host.downcase.include? 'azure'
    `ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no praphan@ppt-#{host}.ddns.net 'docker stop $(docker ps -qa) ; docker rm $(docker ps -qa)'`
  else
    `ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i ~/Dropbox/booking/Docker/ntp.pem ubuntu@ppt#{host.downcase.gsub('aws','')}.ddns.net 'docker stop $(docker ps -qa) ; docker rm $(docker ps -qa)'`
  end
end

# aws
for i in awsGetRunning() do
  puts "aws#{i} running"
  for s in awsGetContainers(i) do
    File.open("#{dir_name}/aws#{i}-#{containerID(s)}", 'w') { |file| file.write(awsGetLogs(i,containerID(s))) }
  end
  d_stop "aws#{i}"
  awsStop i
end

# azure
for i in azureGetRunning() do
  puts "azure#{i} running"
  for s in azureGetContainers(i) do
    File.open("#{dir_name}/azure#{i}-#{containerID(s)}", 'w') { |file| file.write(azureGetLogs(i,containerID(s))) }
  end
  d_stop "azure#{i}"
  azureStop i
end
