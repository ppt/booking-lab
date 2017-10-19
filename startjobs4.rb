#!/usr/bin/env ruby
require 'yaml'
require "./ssh-lib.rb"

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

def booking(host, user, passwd, course, time, session, starttime)
  dockerRunCmd = "#{tmuxNewSession(session)} \"'docker run -it phan/virgin casperjs --user=#{user} --password=#{passwd} --class-time='#{time}' --class-name='#{course}' --start-time='#{starttime}' virgin.js' Enter\""
  `#{$sshCmd} #{hostCmd(host)} #{dockerRunCmd}`
end

courses.each_with_index do |(key, value), index|
  d_stop key
  puts "#{key}"
  session = 1
  value.each { |user, course, time|
    puts "#{user}:#{passwd[user.to_s]} #{time} #{course}"
    booking key, user, passwd[user.to_s], course, time, session, starttime
    session = session + 1
  }
end
