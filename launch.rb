#!/usr/bin/env ruby
def getInstanceIDFromGroup
  `aws ec2 describe-instances --filters "Name=tag:Group,Values=booking" --query "Reservations[*].Instances[*].InstanceId" --output=text`.split
end

def tag(id,name)
  `aws ec2 create-tags --resources #{id} --tags Key=Name,Value=#{name}`
end

def tagNameFromGroup
  getInstanceIDFromGroup().each_with_index {|id,i|
    tag id, "ppt#{i+1}"
  }
end

def launch(count)
  `aws ec2 run-instances --image-id "ami-f164291b" --key-name "ntp"  --instance-type "t2.micro" --tag-specifications "ResourceType=instance,Tags=[{Key=Group,Value=booking}]" --security-group-ids "sg-c9ff42b1" --count #{count}`
end

# assignNameFromGroup()
if ARGV.length > 0
  numVM = ARGV[0]
else
  numVM = 12
end
puts "Launch #{numVM}"
launch(numVM)
puts "Tag VM"
tagNameFromGroup()
