def printLogs(data)
  data.each { |x| 
    host,id,seq,course = x
    puts "#{host} : #{course} (#{seq}) - #{id}"
  }
  puts '-'*80
  puts
end

logsDir = '/Users/praphan/Dropbox/booking/logs/'
latestDir = Dir.glob(logsDir+'*/').max_by {|f| File.mtime(f)}
ok = []
notok = []
Dir.glob(latestDir+'*') { |fname|
  host = File.basename(fname).split(/-/).first
  lines = File.readlines(fname)
  id,seq,course = lines[0].split(' ')
  if lines[-1].downcase().include?('click ok') then
    ok.push([host,id,seq,course])
  else
    notok.push([host,id,seq,course])
  end
}
puts 'NOT OK'
puts '='*6
printLogs (notok)
puts 'OK'
puts '='*2
printLogs (ok)
