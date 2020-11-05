#!/usr/bin/env ruby
def printLogs(data)
  data.each do |x|
    fname, id, seq, course = x
    courseName = "#{course} (#{seq})".ljust(10)
    puts "#{courseName}\t#{id.ljust(10)}\t#{File.basename(fname).ljust(10)}\t#{x[-4]}  #{x[-3]}  #{x[-2]}  #{x[-1]}"
  end
  puts '-' * 80
  puts
end

def getEvent(lines, event)
  (lines.detect { |l| l.include?(event) }).split(' ')[0]
rescue StandardError
  ''
end

def getTimes(lines)
  [
    getEvent(lines, 'START'),
    getEvent(lines, 'Goto Virgin'),
    getEvent(lines, 'Set Language'),
    getEvent(lines, 'Login'),
    getEvent(lines, 'Click Book A Class'),
    getEvent(lines, 'Click Date')
  ]
end

logsDir = if ARGV.empty?
            './logs/'
          # logsDir = '/Users/praphan/Dropbox/booking/logs/'
          else
            ARGV[0]
          end
latestDir = Dir.glob(logsDir + '*/').max_by do |f|
  File.mtime(f)
end

ok = []
notok = []
Dir.glob(latestDir + '*') do |fname|
  host = File.basename(fname).split(/-/).first
  lines = File.readlines(fname)
  id, seq, course = lines[0].split(' ')
  if lines.any? { |s| s.include?('Error!') }
    # if lines[-2].include?(' : Check Time Sleep') then
    notok.push([fname, id, seq, course].concat(getTimes(lines)))
  else
    ok.push([fname, id, seq, course].concat(getTimes(lines)))
  end
end

# printLogs (ok.map { |x| x.map { |y| (if y == nil then '' else y end) } }).sort_by { |x| [x[-3],x[3],x[2],x[1]]}
puts 'NOT OK'
puts '=' * 6
puts "#{'Class'.ljust(10)}\t#{'ID'.ljust(10)}\t#{'File Name'.ljust(12)}\t#{'Start'.ljust(12)}  #{'Goto Virgin'.ljust(12)}  #{'Set Language'.ljust(12)}  #{'Login'.ljust(12)}  #{'Book A Class'.ljust(12)}  #{'Click Date'.ljust(12)}"
printLogs (notok.sort_by { |x| [x[-6]] })
puts 'OK'
puts '=' * 2
puts "#{'Class'.ljust(10)}\t#{'ID'.ljust(10)}\t#{'File Name'.ljust(12)}\t#{'Start'.ljust(12)}  #{'Goto Virgin'.ljust(12)}  #{'Set Language'.ljust(12)}  #{'Login'.ljust(12)}  #{'Book A Class'.ljust(12)}  #{'Click Date'.ljust(12)}"
printLogs (ok.sort_by { |x| [x[-6]] })
