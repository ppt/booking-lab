# aws
# setup
#   brew install aws
#   aws configure
export AWS_ACCESS_KEY_ID=AKIAIKL6GPOHCDE3TL7Q
export AWS_SECRET_ACCESS_KEY=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
export AWS_REGION=ap-southeast-1

function aws-getField {
  aws ec2 describe-instances --filters "Name=tag:Name,Values=ppt$1" --query "Reservations[*].Instances[*].$2"  --output=text

}

function aws-ip {
  aws-getField $1 PublicIpAddress
}

function aws-instanceID {
  aws-getField $1 InstanceId
}

function aws-start {
  if [ $# -eq 0 ]
  then
    for i in {1..6..1}
    do
      aws ec2 start-instances --instance-ids $(aws-instanceID $i)
    done
  else
    aws ec2 start-instances --instance-ids $(aws-instanceID $1)
  fi
}

function aws-status {
  if [ $# -eq 0 ]
  then
    for i in {1..6..1}
    do
      echo aws$i $(aws-getField $i State.Name)
    done
  else
      echo $(aws-getField $1 State.Name)
  fi
}

function aws-stop {
  if [ $# -eq 0 ]
  then
    for i in {1..6..1}
    do
      aws ec2 stop-instances --instance-ids $(aws-instanceID $i)
    done
  else
    aws ec2 stop-instances --instance-ids $(aws-instanceID $1)
  fi
}

function aws-ssh {
  # ssh-aws 3
  # ssh -i ~/Dropbox/booking/Docker/ntp.pem ec2-user@$(aws-ip $1)
  ssh -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' -i ~/Dropbox/booking/Docker/ntp.pem ec2-user@ppt$1.ddns.net
}
