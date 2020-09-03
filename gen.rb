#!/usr/bin/env ruby
require 'yaml'
require './ssh-lib2.rb'
require "time"

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
starttime = '21:59:00'

courses = YAML.load_file jobs
passwd = YAML.load_file passwd

# $dir_name = "logs/#{Time.now.strftime("%d-%m-%Y")}"
# `mkdir logs`
# `mkdir #{$dir_name}`

def runCmd(user, passwd, course, seq, starttime,host,session)
  if host.downcase.include? 'aws'
    "/home/ubuntu/booking2/booking2.js --user=#{user} --password=#{passwd} --seq=#{seq} --class-name='#{course.sub(' ','Space')}' --start-time='#{starttime}'"
  else
    "booking2.js --user=#{user} --password=#{passwd} --seq=#{seq} --class-name='#{course.sub(' ','Space')}' --start-time='#{starttime}'"
  end
end

# def booking(host, user, passwd, course, seq, session, starttime)
def booking(host, session, courses)
  seqCmd = courses.map{|x|
    user, passwd, course, seq, starttime = x
    runCmd(user, passwd, course, seq, starttime, host, session)
  }.join(' ; ')
  # user, passwd, course, seq, starttime = courses
  if host.downcase.include? 'aws'
    s = "#{$sshCmd} #{hostCmd(host)} #{seqCmd} >#{host}-#{session} 2>&1 &"
  else
    s = "#{seqCmd} >#{host}-#{session} 2>&1 &"
  end
  puts s
end

courses.each_with_index do |(key, value), index|
  session = 1
  puts key
  puts '='*10
  for el in value do
    # check if multiple entry    
    if el[0].kind_of?(Array) then
      courses = []
      el.each { |user, course, seq|
        courses.push([user, passwd[user.to_s], course, seq, starttime])
      }
      booking key, session, courses
    else
      user, course, seq = el
      booking key, session, [[user, passwd[user.to_s], course, seq, starttime]]
    end

    session = session + 1
  end
  puts
end
