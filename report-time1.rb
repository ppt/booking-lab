#!/usr/bin/env ruby
def printLogs(data)
  data.each { |x| 
    fname,id,seq,course = x
    courseName = "#{course} (#{seq})".ljust(10)
    puts "#{courseName}\t#{id.ljust(10)}\t#{File.basename(fname).ljust(10)}\t#{x[-4]}  #{x[-3]}  #{x[-2]}  #{x[-1]}"
  }
  puts '-'*80
  puts
end

def getEvent(lines, event)
  begin
    (lines.detect {|l| l.include?(event)}).split(' ')[0]
  rescue
    ''
  end
end

def getTimes(lines)
  [
    getEvent(lines, 'End Check'),
    getEvent(lines, 'Book Class'),
    getEvent(lines, 'Click OK'),
    getEvent(lines, ": END\n")
  ]
end

if ARGV.length == 0
  logsDir = './logs/'
  # logsDir = '/Users/praphan/Dropbox/booking/logs/'
else
  logsDir = ARGV[0]
end
latestDir = Dir.glob(logsDir+'*/').max_by {|f| 
  File.mtime(f)
}

ok = []
notok = []
Dir.glob(latestDir+'*') { |fname|
  host = File.basename(fname).split(/-/).first
  lines = File.readlines(fname)
  id,seq,course = lines[0].split(' ')
  if lines[-1].include?('END') then
  #   if lines[-2].downcase().include?('timeout') then
  #     notok.push([fname,id,seq,course])
  #   else
      ok.push([fname,id,seq,course].concat(getTimes(lines)))
  #   end
  else
    notok.push([fname,id,seq,course].concat(getTimes(lines)))
  end
}
puts 'NOT OK'
puts '='*6
puts "#{'Class'.ljust(10)}\t#{'ID'.ljust(10)}\t#{'File Name'.ljust(12)}\t#{'End Check'.ljust(12)}  #{'Booking'.ljust(12)}  #{'Click OK'.ljust(12)}  #{'END'.ljust(12)}"
printLogs (notok.map { |x| x.map { |y| (if y == nil then '' else y end) } }).sort_by { |x| [x[-2],x[-1],x[2],x[1]]}
puts 'OK'
puts '='*2
puts "#{'Class'.ljust(10)}\t#{'ID'.ljust(10)}\t#{'File Name'.ljust(12)}\t#{'End Check'.ljust(12)}  #{'Booking'.ljust(12)}  #{'Click OK'.ljust(12)}  #{'END'.ljust(12)}"
printLogs (ok.map { |x| x.map { |y| (if y == nil then '' else y end) } }).sort_by { |x| [x[-2],x[-1],x[2],x[1]]}
