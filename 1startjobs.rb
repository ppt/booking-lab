#!/usr/bin/env ruby
require 'yaml'

if ARGV.length == 0
  jobs = 'jobs.yml'
  passwd = 'user-passwd.yml'
elsif ARGV.length == 1
  jobs = ARGV[0]
  passwd = 'user-passwd.yml'
else
  jobs = ARGV[0]
  passwd = ARGV[1]
end

courses = YAML.load_file jobs
passwd = YAML.load_file passwd

def d_stop(host)
  if host.downcase.include? 'azure'
    `ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no praphan@ppt-#{host}.ddns.net 'docker stop $(docker ps -qa) ; docker rm $(docker ps -qa)'`
  else
    `ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i ~/Dropbox/booking/Docker/ntp.pem ec2-user@ppt#{host.downcase.gsub('aws','')}.ddns.net 'docker stop $(docker ps -qa) ; docker rm $(docker ps -qa)'`
  end
end

def booking(host, user, passwd, course, time, session)
  if host.downcase.include? 'azure'
    `ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no praphan@ppt-#{host}.ddns.net tmux new-session -d -s t#{session}`
    s = "ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no praphan@ppt-#{host}.ddns.net tmux send-keys -t t#{session} \"'docker run -it phan/casperjs-mac-2 casperjs --web-security=false --ignore-ssl-errors=true --ssl-protocol=any --user=#{user} --password=#{passwd} --class-time='#{time}' --class-name='#{course}' booking.coffee' Enter\""
    p s
    `#{s}`

  else
    `ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i ~/Dropbox/booking/Docker/ntp.pem ec2-user@ppt#{host.downcase.gsub('aws','')}.ddns.net tmux new-session -d -s t#{session}`
    s = "ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i ~/Dropbox/booking/Docker/ntp.pem ec2-user@ppt#{host.downcase.gsub('aws','')}.ddns.net tmux send-keys -t t#{session} \"'docker run -it phan/casperjs-mac-2 casperjs --web-security=false --ignore-ssl-errors=true --ssl-protocol=any --user=#{user} --password=#{passwd} --class-time='#{time}' --class-name='#{course}' booking.coffee' Enter\""
    p s
    `#{s}`
  end
end

courses.each_with_index do |(key, value), index|
  d_stop key
  puts "#{key}"
  session = 1
  value.each { |user, course, time|
    puts "#{user} #{time} #{course}"
    booking key, user, passwd[user.to_s], course, time, session
    session = session + 1
  }
end
