#!/usr/bin/env ruby
require 'yaml'
require './ssh-lib2.rb'
require "time"

starttime = '21:59:00'
$sleeptime = 400
$checktime = '22:00:05'

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

p jobs,passwd

courses = YAML.load_file jobs
passwd = YAML.load_file passwd

$dir_name = "logs/#{Time.now.strftime("%d-%m-%Y")}"
`mkdir logs`
`mkdir #{$dir_name}`

def runCmd(user, passwd, course, seq, starttime,host,session)
  if host.downcase.include? 'aws'
    "setsid /home/ubuntu/booking2/booking5.js --user=#{user} --password=#{passwd} --seq=#{seq} --class-name='#{course.sub(' ','Space')}' --start-time='#{starttime}' --sleeptime=#{$sleeptime} --checktime='#{$checktime}' >#{host}-5-#{session} 2>&1 &"
  else
    "nohup ~/booking2/booking5.js --user=#{user} --password=#{passwd} --seq='#{seq}' --class-name='#{course.sub(' ','Space')}' --start-time='#{starttime}' --sleeptime=#{$sleeptime} --checktime='#{$checktime}' >#{host}-5-#{session} 2>&1 &"
  end
end

# def booking(host, user, passwd, course, seq, session, starttime)
def booking(host, session, courses)
  seqCmd = courses.map{|x|
    user, passwd, course, seq, starttime = x
    runCmd(user, passwd, course, seq, starttime, host, session)
  }.join(' ; ')
  # user, passwd, course, seq, starttime = courses
  s = "#{$sshCmd} #{hostCmd(host)} \"#{seqCmd}\""
  puts s
  `#{s}`
end

courses.each_with_index do |(key, value), index|
  session = 1
  for el in value do
    # check if multiple entry    
    if el[0].kind_of?(Array) then
      courses = []
      el.each { |user, course, seq|
        puts "#{user} #{seq} #{course}"
        courses.push([user, passwd[user.to_s], course, seq, starttime])
      }
      booking key, session, courses
    else
      user, course, seq = el
      puts "#{user} #{seq} #{course}"
      booking key, session, [[user, passwd[user.to_s], course, seq, starttime]]
    end

    session = session + 1
  end
end
