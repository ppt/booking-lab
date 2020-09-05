#!/usr/bin/env ruby

# scp -i ~/Dropbox/booking/Docker/ntp.pem ubuntu@ppt1.ddns.net:aws1-1 .

require "./aws-lib2.rb"
require "./azure-lib.rb"
require "./ssh-lib2.rb"
require "./pc-lib3.rb"
require "time"

def containerID(s)
  s.split(' ')[0]
end

if ARGV.empty?
  puts "Sleep #{Time.parse("22:09") - Time.now} seconds"
  sleep(Time.parse("22:09") - Time.now)
end

$dir_name = "logs/#{Time.now.strftime("%d-%m-%Y")}"
`mkdir logs`
`mkdir #{$dir_name}`

def awsGetLogs(aws_id)
  `#{$sshCmd} -i ~/Dropbox/booking/Docker/ntp.pem ubuntu@ppt#{aws_id}.ddns.net ls`.split("\n").select {|name|name.downcase.include? "aws" }
end

# aws
def stopAWS
  for i in awsGetRunning() do
    puts "aws#{i} running"
    for fname in awsGetLogs(i) do
      `scp -i ~/Dropbox/booking/Docker/ntp.pem ubuntu@ppt1.ddns.net:#{fname} #{$dir_name}`

    end
    # awsTerminate i
  end
end

def pptGetLogs(user, host)
  `ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"  #{user}@ppt-#{host}.ddns.net ls`.split("\n").select {|name|name.downcase.include? "#{host}" }
end

def stopPCMac(user,host)
  if pcRunning?(user,host)
    for fname in pptGetLogs(user,host) do
      `scp #{user}@ppt-#{host}.ddns.net:#{fname} #{$dir_name}`
      # `ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"  #{user}@ppt-#{host}.ddns.net rm #{fname}`
    end
    `ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"  #{user}@ppt-#{host}.ddns.net pkill -f booking`
  end
end

stopAWS()
stopPCMac('praphan', 'macppt')
stopPCMac('nattaya', 'macntp')
# stopPCMac('macntp')
