#!/usr/bin/env ruby
def printLogs(data)
  data.each do |x|
    fname, id, seq, course = x
    courseName = "#{course} (#{seq})".ljust(12)
    puts "#{courseName}#{id.ljust(9)} #{File.basename(fname).ljust(11)} #{x[-5]}    #{x[-4]}  #{x[-3]}  #{x[-2]}  #{x[-1]}"
  end
  puts '-' * 80
  puts
end

def getEvent(lines, event)
  (lines.detect { |l| l.include?(event) }).split(' ')[0]
rescue StandardError
  ''
end

def countEvent(lines, event)
  lines.count { |l| l.include?(event) }
rescue StandardError
  ''
end

def getTimes(lines)
  [
    countEvent(lines, 'Poll Timeout'),
    getEvent(lines, 'End Check'),
    getEvent(lines, 'Book Class'),
    getEvent(lines, 'Click OK'),
    getEvent(lines, ": END\n")
  ]
end

logsDir = './logs/'
# logsDir = '/Users/praphan/Dropbox/booking/logs/'
latestDir = Dir.glob(logsDir + '*/').max_by do |f|
  File.mtime(f)
end
ok = []
notok = []
Dir.glob(latestDir + '*') do |fname|
  host = File.basename(fname).split(/-/).first
  lines = File.readlines(fname)
  id, seq, course = lines[0].split(' ')
  if lines[-1].include?('END')
    #   if lines[-2].downcase().include?('timeout') then
    #     notok.push([fname,id,seq,course])
    #   else
    ok.push([fname, id.split(':')[0], seq, course].concat(getTimes(lines)))
  #   end
  else
    notok.push([fname, id.split(':')[0], seq, course].concat(getTimes(lines)))
  end
end
puts 'NOT OK'
puts '=' * 6
puts "#{'Class'.ljust(11)} #{'ID'.ljust(9)} #{'File Name'.ljust(11)} Poll #{'End Check'.ljust(12)}  #{'Booking'.ljust(12)}  #{'Click OK'.ljust(12)}  #{'END'.ljust(12)}"
printLogs (notok.map { |x| x.map { |y| (y.nil? ? '' : y) } }).sort_by { |x| [x[3], x[2], x[1]] }
puts 'OK'
puts '=' * 2
puts "#{'Class'.ljust(11)} #{'ID'.ljust(9)} #{'File Name'.ljust(11)} Poll #{'End Check'.ljust(12)}  #{'Booking'.ljust(12)}  #{'Click OK'.ljust(12)}  #{'END'.ljust(12)}"
printLogs (ok.map { |x| x.map { |y| (y.nil? ? '' : y) } }).sort_by { |x| [x[3], x[2], x[1]] }
