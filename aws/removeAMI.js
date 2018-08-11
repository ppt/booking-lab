const http = require("http");
const AWS = require("aws-sdk");
AWS.config.update({ region: "ap-southeast-1" });

const ec2 = {
  name: reservation => reservation.Instances[0].Tags[0].Value,
  // pending | running | stopped | stopping | shutting-down | terminated
  state: reservation => reservation.Instances[0].State.Name,
  id: reservation => reservation.Instances[0].InstanceId,
  ip: reservation => reservation.Instances[0].PublicIpAddress,
  status: reservation => reservation.Instances[0].State.Name,
  getIdByName: async name => {
    const instance = await new AWS.EC2()
      .describeInstances({
        Filters: [
          {
            Name: "tag:Name",
            Values: [name]
          }
        ]
      })
      .promise();
    let id = ec2.id(instance.Reservations[0]);
    console.log(name, id);
    return id;
  },
  getNoDays: async () => {
    var params = {
      Bucket: "ppt-booking",
      Key: "calendar.csv"
    };
    let calendar = await new AWS.S3().getObject(params).promise();
    calendar = calendar.Body.toString("utf-8");
    console.log(`calendar: ${calendar}`);
    const day = new Date().getDay();
    return calendar
      .replace(/[^0-9,]/g, "")
      .split(",")
      .map(x => parseInt(x))[day];
  },
  start: async () => {
    console.log("Start EC2");
    let nodays = await ec2.getNoDays();
    console.log(`Start ${nodays} VMs`);
    // Create EC2
    for (let i = 1; i <= nodays; i++) {
      const instanceParams = {
        ImageId: "ami-f164291b",
        InstanceType: "t2.micro",
        KeyName: "ntp",
        SecurityGroupIds: ["sg-c9ff42b1"],
        MinCount: 1,
        MaxCount: 1,
        TagSpecifications: [
          {
            ResourceType: "instance",
            Tags: [
              {
                Key: "Name",
                Value: `ppt${i}`
              }
            ]
          }
        ]
      };
      let data = await new AWS.EC2()
        .runInstances(instanceParams)
        .promise();
      console.log(data);
    }
  },
  getRunning: async () => {
    const data = await new AWS.EC2().describeInstances({}).promise();
    let running = [];
    data.Reservations.forEach(element => {
      if (ec2.status(element) == "running") {
        running.push([ec2.name(element), ec2.ip(element)]);
      }
    });
    return running;
  },
  assignNOIP: async () => {
    console.log("Assign NOIP");
    const running = await ec2.getRunning();
    running.forEach(([name, ip]) => {
      const url = `http://praphan:password@dynupdate.no-ip.com/nic/update?hostname=${name}.ddns.net&myip=${ip}`;
      http.get(url);
      console.log(`${name}, ${ip}, ${url}`);
    });
  },
  describeImages: async name => {
    const images = await new AWS.EC2()
      .describeImages({
        Filters: [
          {
            Name: "name",
            Values: [name]
          }
        ]
      })
      .promise();
    return images;
  },
  getImageState: async name => {
    const instance = await ec2.describeImages(name);
    if (instance.Images.length == 0) return "no image";
    const state = instance.Images[0].State;
    console.log(`getImageState ${name}: ${state}`);
    return state;
  },
  getImageId: async name => {
    const instance = await ec2.describeImages(name);
    const id = instance.Images[0].ImageId;
    console.log(`getImageId ${name}: ${id}`);
    return id;
  },
  createAMI: async (amiName, instanceName) => {
    // aws ec2 create-image --instance-id $(aws-getField $1 InstanceId) --name $2

    console.log(`Create ${amiName} AMI from ${instanceName}`);
    const id = await ec2.getIdByName(instanceName);
    const params = {
      InstanceId: id,
      Name: amiName
    };
    const data = await new AWS.EC2().createImage(params).promise();
    var tagparams = {
      Resources: [data.ImageId],
      Tags: [
        {
          Key: "Name",
          Value: amiName
        }
      ]
    };
    await new AWS.EC2().createTags(tagparams).promise();
  },
  getSnapShots: async name => {
    const instance = await ec2.describeImages(name);
    console.dir(instance);
    console.dir(instance.Images[0].BlockDeviceMappings);
    const id = instance.Images[0].BlockDeviceMappings[0].Ebs.SnapshotId;
    console.log(`getSnapShotId ${name}: ${id}`);
    return id;
  },
  deleteSnapshot: async id => {
    let params = {
      SnapshotId: "snap-1234567890abcdef0"
    };
    await new AWS.EC2().deleteSnapshot(params).promise();
  },
  deregisterAMI: async name => {
    const id = await ec2.getImageId(name);
    var params = {
      ImageId: id
    };
    await ec2.deregisterImage(params).promise();
  }
};
async function main() {
  const name = "Booking";
  const snapshot = await ec2.getSnapShots(name);
  // await ec2.deregisterAMI(name);
  ec2.deleteSnapshot(snapshot);
}

main();
