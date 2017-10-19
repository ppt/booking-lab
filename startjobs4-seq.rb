#!/usr/bin/env ruby
require 'yaml'
require './ssh-lib.rb'

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

def booking(host, user, passwd, course, seq, session, starttime)
  dockerRunCmd = "tmux send-keys -t t#{session} \"'docker run -it phan/virgin casperjs --user=#{user} --password=#{passwd} --seq='#{seq}' --class-name='#{course}' --start-time='#{starttime}' virgin-seq.js' Enter\""
  s = "#{$sshCmd} #{hostCmd(host)} #{dockerRunCmd}"
  p s
  `#{s}`
end

courses.each_with_index do |(key, value), index|
  d_stop key
  puts "#{key}"
  session = 1
  for el in value do
    tmux_newSession = "tmux new-session -d -s t#{session}"
    p "#{$sshCmd} #{hostCmd(key)} #{tmux_newSession}"
    `#{$sshCmd} #{hostCmd(key)} #{tmux_newSession}`
    # check if multiple entry
    
    if el[0].kind_of?(Array) then
      el.each { |user, course, seq|
        puts "#{user} #{seq} #{course}"
        booking key, user, passwd[user.to_s], course, seq, session, starttime
      }
    else
      user, course, seq = el
      puts "#{user} #{seq} #{course}"
      booking key, user, passwd[user.to_s], course, seq, session, starttime
    end

    session = session + 1
  end
end
