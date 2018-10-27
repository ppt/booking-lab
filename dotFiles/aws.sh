# aws
# setup
#   brew install aws
#   aws configure

# using by s3-editor
export AWS_REGION=ap-southeast-1
export EDITOR=/usr/bin/nano
export AMI_IMAGE=ami-0d06e080e9563c354
export EC2_VPC=sg-0ea69fa9251003612

function aws-getField {
  aws ec2 describe-instances --filters "Name=tag:Name,Values=ppt$1" --query "Reservations[*].Instances[*].$2"  --output=text

}

function aws-ip {
  aws-getField $1 PublicIpAddress
}

function aws-instanceID {
  aws-getField $1 InstanceId
}

function aws-ownerID {
aws ec2 describe-instances --filters "Name=tag:Name,Values=ppt$1" --query "Reservations[*].OwnerId" --output=text
}

function aws-start {
  if [ $# -eq 0 ]
  then
    for i in {1..12..1}
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
    for i in {1..12..1}
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
    for i in {1..12..1}
    do
      aws ec2 stop-instances --instance-ids $(aws-instanceID $i)
    done
  else
    aws ec2 stop-instances --instance-ids $(aws-instanceID $1)
  fi
}

function aws-terminate {
  if [ $# -eq 0 ]
  then
    for i in {1..12..1}
    do
      aws ec2 terminate-instances --instance-ids $(aws-instanceID $i)
      aws ec2 delete-tags --resource $(aws-instanceID $i) --tags Key=Name
    done
  else
    aws ec2 terminate-instances --instance-ids $(aws-instanceID $1)
    aws ec2 delete-tags --resource $(aws-instanceID $1) --tags Key=Name
  fi
}

function aws-launch {
    if [ $# -eq 0 ]
    then
      for ((i = 1; i <= 12; i++ ));
      do
        aws ec2 run-instances --image-id "$AMI_IMAGE" --key-name "ntp"  --instance-type "t2.micro" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ppt$i}]" --security-group-ids "$EC2_VPC"
      done
    else
      for ((i = 1; i <= $1; i++ ));
      do
        aws ec2 run-instances --image-id "$AMI_IMAGE" --key-name "ntp"  --instance-type "t2.micro" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ppt$i}]" --security-group-ids "$EC2_VPC"
      done
    fi
    aws-noip
}

function aws-ssh-direct {
  ssh -i ~/Dropbox/booking/Docker/ntp.pem -o StrictHostKeyChecking=no ubuntu@$1
}

function aws-ssh {
  # ssh-aws 3
  sed "/^ppt$1.ddns.net/d" ~/.ssh/known_hosts > ~/.ssh/known_hosts
  if [ $# -eq 1 ]
  then
    ssh -i ~/Dropbox/booking/Docker/ntp.pem -o StrictHostKeyChecking=no ubuntu@ppt$1.ddns.net
  else
    i=$1
    shift
    ssh -i ~/Dropbox/booking/Docker/ntp.pem -o StrictHostKeyChecking=no ubuntu@ppt$i.ddns.net $@
  fi
}

function aws-noip {
  if [ $# -eq 0 ]
  then
    for i in {1..12..1}
    do
      curl http://praphan:password@dynupdate.no-ip.com/nic/update\?hostname\=ppt$i.ddns.net\&myip\=$(aws-ip $i)
    done
  else
    curl http://praphan:password@dynupdate.no-ip.com/nic/update\?hostname\=ppt$1.ddns.net\&myip\=$(aws-ip $1)
  fi
}

# aws-createAMI 1-9 AMIName
function aws-createAMI {
  aws ec2 create-image --instance-id $(aws-getField $1 InstanceId) --name $2
}

# aws-getFieldAMI name (ImageId | State)
function aws-getFieldAMI {
  aws ec2 describe-images --filters Name=name,Values=$1 --query "Images[*].{ID:$2}" --output=text
}

# list all AMI attributes
# aws-describeAMI 1-9
function aws-desribeAMI {
    aws ec2 describe-images --filters Name=name,Values=$1
}

# delete AMI
# aws-deregisterAMI AMIName
function aws-deregisterAMI {
  aws ec2 deregister-image --image-id $(aws-getFieldAMI $1 ImageId)
}

# WARN: Need Instance ownerID, using ppt1 need to update later
# aws-describeSnapshots snapshot-position(0-9)
function aws-describeSnapshots {
  aws ec2 describe-snapshots --owner-ids $(aws-ownerID 1) --query "Snapshots[*].{ID:VolumeId}" --output=text
}

# WARN: Need Instance ownerID, using ppt1 need to update later
# aws-getFieldSnapshot 0-9 fieldname
function aws-getFieldSnapshot {
  aws ec2 describe-snapshots --owner-ids $(aws-ownerID 1) --query "Snapshots[$1].{ID:$2}" --output=text
}

# aws-snapshotID 0-9
function aws-snapshotID {
  aws-getFieldSnapshot $1 SnapshotId
}

# aws-deleteSnapshot 0
function aws-deleteSnapshot {
  aws ec2 delete-snapshot --snapshot-id $(aws-snapshotID $1)
}

function aws-editCalendar {
  s3-edit edit s3://ppt-booking/calendar.csv
}

# create security-group for ssh
# aws ec2 create-security-group --group-name pptec2 --description "define ssh"
# define group with ssh protocal need to config group-id
# aws ec2 authorize-security-group-ingress --group-id sg-c9ff42b1 --protocol tcp --port 22 --cidr 0.0.0.0/0 --region ap-southeast-1

# lauanch instance
# aws ec2 run-instances --image-id "ami-93286579" --key-name "ntp"  --instance-type "t2.small" --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ppt21}]' --security-group-ids sg-c9ff42b1
