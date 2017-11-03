#!/usr/bin/env ruby
def printLogs(data)
  data.each { |x| 
    fname,id,seq,course = x
    courseName = "#{course} (#{seq})".ljust(20)
    puts "#{courseName}\t#{id.ljust(10)}\t#{File.basename(fname)}"
  }
  puts '-'*80
  puts
end

logsDir = './logs/'
latestDir = Dir.glob(logsDir+'*/').max_by {|f| File.mtime(f)}
ok = []
notok = []
Dir.glob(latestDir+'*') { |fname|
  host = File.basename(fname).split(/-/).first
  lines = File.readlines(fname)
  id,seq,course = lines[0].split(' ')
  if lines[-1].downcase().include?('click ok') then
    if lines[-2].downcase().include?('timeout') then
      notok.push([fname,id,seq,course])
    else
      ok.push([fname,id,seq,course])
    end
  else
    notok.push([fname,id,seq,course])
  end
}
puts 'NOT OK'
puts '='*6
printLogs (notok).sort_by { |x| [x[3],x[2],x[1]]}
puts 'OK'
puts '='*2
printLogs (ok).sort_by { |x| [x[3],x[2],x[1]]}
