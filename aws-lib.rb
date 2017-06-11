def awsStatus(id)
  `bash -c 'source ~/dotFiles/aws.sh; aws-status #{id}'`[0..-2]
end


def awsIsRunning(id)
  awsStatus(id) == 'running'
end

def awsStart(id)
  `bash -c 'source ~/dotFiles/aws.sh; aws-start #{id}'`
end

def awsStop(id)
  `bash -c 'source ~/dotFiles/aws.sh; aws-stop #{id}'`
end


def awsGetRunning()
  result = []
  for i in 1..8 do
    if awsIsRunning(i)
      result.push i
    end
  end
  return result
end

def awsGetContainers(aws_id)
  `ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ~/Dropbox/booking/Docker/ntp.pem ubuntu@ppt#{aws_id}.ddns.net docker ps -a`.split("\n")[1..-1]
end

def awsGetLogs(aws_id, container_id)
  `ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ~/Dropbox/booking/Docker/ntp.pem ubuntu@ppt#{aws_id}.ddns.net docker logs #{container_id}`
end
