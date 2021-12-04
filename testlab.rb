#!/usr/bin/env ruby

fname = '/Users/praphan/Dropbox/booking/logs/19-09-2020/aws6-5-2'
# fname = '/Users/praphan/Dropbox/booking/logs/18-09-2020/aws1-5-1'
lines = File.readlines(fname)

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
p getTimes(lines)
endcheck = getEvent(lines, 'End Check')
bookclass = getEvent(lines, 'Book Class')
clickok = getEvent(lines, 'Click OK')
endend = getEvent(lines, ": END\n")
# endcheck = (lines.detect {|l| l.include?('End Check')}).split(' ')[0]
# bookclass = (lines.detect {|l| l.include?('Book Class')}).split(' ')[0]
# clickok = (lines.detect {|l| l.include?('Click OK')}).split(' ')[0]
# endend = (lines.detect {|l| l.include?(": END\n")}).split(' ')[0]
p endcheck, bookclass, clickok, endend