#!/usr/bin/env ruby
require 'aws-sdk-s3'

s3 = Aws::S3::Client.new
resp = s3.get_object(bucket:'ppt-booking', key:'calendar.csv')

calendar = resp.body.read
calendar = calendar.gsub("\n",'').split(',').map!(&:to_i)

txt = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
for i in 0..calendar.length-1 do
  puts "#{txt[i]} : #{calendar[i]} instances"
end
puts
