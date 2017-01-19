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
starttime = '22:09:30'

courses = YAML.load_file jobs
passwd = YAML.load_file passwd

def d_stop(host)
  if host.downcase.include? 'azure'
    `ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no praphan@ppt-#{host}.ddns.net 'docker stop $(docker ps -qa) ; docker rm $(docker ps -qa)'`
  else
    `ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i ~/Dropbox/booking/Docker/ntp.pem ec2-user@ppt#{host.downcase.gsub('aws','')}.ddns.net 'docker stop $(docker ps -qa) ; docker rm $(docker ps -qa)'`
  end
end

def booking(host, user, passwd, course, seq, session, starttime)
  if host.downcase.include? 'azure'
    `ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no praphan@ppt-#{host}.ddns.net tmux new-session -d -s t#{session}`
    s = "ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no praphan@ppt-#{host}.ddns.net tmux send-keys -t t#{session} \"'docker run -it phan/virgin casperjs --user=#{user} --password=#{passwd} --seq='#{seq}' --class-name='#{course}' --start-time='#{starttime}' virgin-seq.js' Enter\""
    p s
    `#{s}`

  else
    `ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i ~/Dropbox/booking/Docker/ntp.pem ec2-user@ppt#{host.downcase.gsub('aws','')}.ddns.net tmux new-session -d -s t#{session}`
    s = "ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i ~/Dropbox/booking/Docker/ntp.pem ec2-user@ppt#{host.downcase.gsub('aws','')}.ddns.net tmux send-keys -t t#{session} \"'docker run -it phan/virgin casperjs --user=#{user} --password=#{passwd} --seq='#{seq}' --class-name='#{course}' --start-time='#{starttime}' virgin-seq.js' Enter\""
    p s
    `#{s}`
  end
end

courses.each_with_index do |(key, value), index|
  d_stop key
  puts "#{key}"
  session = 1
  value.each { |user, course, seq|
    puts "#{user} #{seq} #{course}"
    booking key, user, passwd[user.to_s], course, seq, session, starttime
    session = session + 1
  }
end
