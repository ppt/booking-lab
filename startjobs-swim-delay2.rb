#!/usr/bin/env ruby
require 'yaml'
require './ssh-lib2.rb'
require "time"

starttimeS = Time.parse '19:30:50'

delay = 25 # in seconds
$sleeptime = 100
$checktime = '21:59:55'
$chromeTimeout = 600000;
$pollTimeout = 4000


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
    "setsid /home/ubuntu/booking2/booking-swim2.js --user=#{user} --password=#{passwd} --seq=#{seq} --class-name='#{course.sub(' ','Space')}' --start-time='#{starttime}' --sleeptime=#{$sleeptime} --pollTimeout=#{$pollTimeout} --checktime='#{$checktime}' --chrometimeout=#{$chromeTimeout} >#{host}-5-#{session} 2>&1 &"
  elsif host.downcase.include? 'pc'
    "setsid /home/praphan/booking2/booking-swim-pc.js --user=#{user} --password=#{passwd} --seq=#{seq} --class-name='#{course.sub(' ','Space')}' --start-time='#{starttime}' --sleeptime=#{$sleeptime} --pollTimeout=#{$pollTimeout} --checktime='#{$checktime}' --chrometimeout=#{$chromeTimeout} >#{host}-5-#{session} 2>&1 &"
  else
    "nohup ~/booking2/booking-swim2.js --user=#{user} --password=#{passwd} --seq='#{seq}' --class-name='#{course.sub(' ','Space')}' --start-time='#{starttime}' --sleeptime=#{$sleeptime} --pollTimeout=#{$pollTimeout} --checktime='#{$checktime}' --chrometimeout=#{$chromeTimeout} >#{host}-5-#{session} 2>&1 &"
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
        starttime = starttimeS.strftime('%k:%M:%S')
        starttimeS += delay
        puts "#{user} #{seq} #{course}"
        courses.push([user, passwd[user.to_s], course, seq, starttime])
      }
      booking key, session, courses
    else
      user, course, seq = el
      starttime = starttimeS.strftime('%k:%M:%S')
      starttimeS += delay
      puts "#{user} #{seq} #{course}"
      booking key, session, [[user, passwd[user.to_s], course, seq, starttime]]
    end

    session = session + 1
  end
end
