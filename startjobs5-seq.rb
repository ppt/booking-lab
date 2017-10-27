#!/usr/bin/env ruby
require 'yaml'
require './ssh-lib2.rb'

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
starttime = '22:13:30'

courses = YAML.load_file jobs
passwd = YAML.load_file passwd

def dockerRunCmd(user, passwd, course, seq, starttime)
  "docker run -it phan/virgin casperjs --user=#{user} --password=#{passwd} --seq='#{seq}' --class-name='#{course}' --start-time='#{starttime}' virgin-seq.js"
end

# def booking(host, user, passwd, course, seq, session, starttime)
def booking(host, session, courses)
  seqCmd = courses.map{|x|
    user, passwd, course, seq, starttime = x
    dockerRunCmd(user, passwd, course, seq, starttime)
  }.join(' ; ')
  # user, passwd, course, seq, starttime = courses
  s = "#{$sshCmd} #{hostCmd(host)} #{tmuxSession(session)} \"'#{seqCmd}' Enter\""
  p s
  `#{s}`
end

courses.each_with_index do |(key, value), index|
  d_stop key
  puts "#{key}"
  session = 1
  for el in value do
    p "#{$sshCmd} #{hostCmd(key)} #{tmuxNewSession(session)}"
    `#{$sshCmd} #{hostCmd(key)} #{tmuxNewSession(session)}`
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
