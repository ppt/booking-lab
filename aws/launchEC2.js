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
  sleep: ms => new Promise(resolve => setTimeout(resolve, ms)),
  getNoDays: async () => {
    var params = {
      Bucket: "ppt-booking",
      Key: "calendar.csv"
    };
    let calendar = await new AWS.S3().getObject(params).promise();
    calendar = calendar.Body.toString("utf-8");
    console.log("calendar", calendar);
    const day = new Date().getDay();
    return calendar
      .replace(/[^0-9,]/g, "")
      .split(",")
      .map(x => parseInt(x))[day];
  },
  tag: async (instanceId, tag, value) => {
    var params = {
      Resources: [instanceId],
      Tags: [
        {
          Key: tag,
          Value: value
        }
      ]
    };
    await new AWS.EC2().createTags(params).promise();
  },
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
    console.log("getIdByName", name, id);
    return id;
  },
  start: async (imageId, novms) => {
    console.log("Start EC2", novms);
    // Create EC2
    const instanceParams = {
      ImageId: imageId,
      InstanceType: "t2.micro",
      KeyName: "ntp",
      SecurityGroupIds: ["sg-c9ff42b1"],
      MinCount: novms,
      MaxCount: novms,
      TagSpecifications: [
        {
          ResourceType: "instance",
          Tags: [
            {
              Key: "Group",
              Value: "booking"
            }
          ]
        }
      ]
    };
    let data = await new AWS.EC2().runInstances(instanceParams).promise();
    console.log(data);
  },
  getRunning: async () => {
    const data = await new AWS.EC2().describeInstances({}).promise();
    let running = [];
    data.Reservations.forEach(r => {
      r.Instances.forEach(e => {
        if (e.State.Name == "running") {
          running.push({
            id: e.InstanceId,
            ip: e.PublicIpAddress,
            state: e.State.Name
          });
        }
      });
    });
    return running;
  },
  getRunningByGroup: async group => {
    const params = {
      Filters: [
        {
          Name: "tag:Group",
          Values: [group]
        }
      ]
    };
    const data = await new AWS.EC2().describeInstances(params).promise();
    let running = [];
    data.Reservations.forEach(r => {
      r.Instances.forEach(e => {
        console.dir(e.State);
        if (e.State.Name == "running") {
          running.push({
            id: e.InstanceId,
            ip: e.PublicIpAddress,
            state: e.State.Name
          });
        }
      });
    });
    return running;
  },
  describeInstances: async id => {
    const params = {
      InstanceIds: [id]
    };
    const data = await new AWS.EC2().describeInstances(params).promise();
    return data;
  },
  describeImagesById: async id => {
    const data = await new AWS.EC2()
      .describeImages({
        ImageIds: [id]
      })
      .promise();
    const img = data.Images[0];
    return {
      id: img.ImageId,
      state: img.State,
      snapshot: img.BlockDeviceMappings[0].Ebs.SnapshotId
    };
  },
  describeImagesByName: async name => {
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
    console.log("getImageState", name, state);
    return state;
  },
  getImageId: async name => {
    const instance = await ec2.describeImages(name);
    const id = instance.Images[0].ImageId;
    console.log("getImageId", name, id);
    return id;
  },
  createAMI: async (amiName, instanceName) => {
    // aws ec2 create-image --instance-id $(aws-getField $1 InstanceId) --name $2

    console.log("createAMI", amiName, instanceName);
    const id = await ec2.getIdByName(instanceName);
    const params = {
      InstanceId: id,
      Name: amiName
    };
    console.dir(params);
    const data = await new AWS.EC2().createImage(params).promise();
    console.dir(data);
  },
  describeSnapshot: async id => {
    const data = await new AWS.EC2()
      .describeSnapshots({
        SnapshotIds: [id]
      })
      .promise();
    return data.Snapshots[0];
  },
  getSnapShotId: async imageName => {
    let data = await ec2.describeImages(imageName);
    const snapshotId = data.Images[0].BlockDeviceMappings[0].Ebs.SnapshotId;
    console.log("getSnapShotId", snapshotId);
    return snapshotId;
  },
  deleteSnapShot: async snapshotId => {
    const params = {
      SnapshotId: snapshotId
    };
    const data = await new AWS.EC2().deleteSnapshot(params).promise();
    return data;
  },
  deregisterAMI: async imageName => {
    const imageId = await ec2.getImageId(imageName);
    const params = {
      ImageId: imageId
    };
    const data = await new AWS.EC2().deregisterImage(params).promise();
    return data;
  }
};

async function createAMIFromBookingInstance(instanceName, imageName) {
  console.log("Create AMI from booking Instance");
  const state = await ec2.getImageState(imageName);
  if (state == "available") {
    console.log("createAMIFromBookingInstance", imageName, state);
  } else {
    await ec2.createAMI(imageName, instanceName);
    console.log("Wait for AMI to be available");
    let state = await ec2.getImageState(imageName);
    let time = 0;
    while (state != "available") {
      console.log("Image State", state, time, "sec");
      state = await ec2.getImageState(imageName);
      await ec2.sleep(5000);
      time = time + 5;
    }
  }
}

async function launchEC2(imageName) {
  console.log("Launch EC2 from ${imageName} and wait until all running");
  const novms = await ec2.getNoDays();
  const group = "booking";
  const imageId = await ec2.getImageId(imageName);
  await ec2.start(imageId, novms);

  // wait until all vms running
  let running = await ec2.getRunningByGroup(group);
  let time = 0;
  while (novms != running.length) {
    running = await ec2.getRunning();
    console.log("Wait", novms - running.length, "vms,", time, "sec");
    await ec2.sleep(5000);
    time = time + 5;
  }

  for (let i = 0; i < running.length; i++) {
    const name = "ppt" + (i + 1);
    const element = running[i];
    await ec2.tag(element.id, "Name", name);
    const url =
            "http://praphan:password@dynupdate.no-ip.com/nic/update?hostname=" +
            name +
            ".ddns.net&myip=" +
            element.ip;
    await http.get(url);
  }
}

async function deleteAMI(imageName) {
  const snapshotId = await ec2.getSnapShotId(imageName);
  const imageId = await ec2.getImageId(imageName);
  await ec2.deregisterAMI(imageName);
  console.log("Deregister AMI", imageId);
  await ec2.deleteSnapShot(snapshotId);
  console.log("Delete Snapshot", snapshotId);
}

async function main() {
  const instanceName = "booking";
  const imageName = "booking-ami";
  await createAMIFromBookingInstance(instanceName, imageName);
  await launchEC2(imageName);
  await deleteAMI(imageName);
}

// main();

// exports.handler = async event => {
//   await main();
// }

test();

async function test() {
  const running = await ec2.getRunning();
  let ami = "";
  // console.dir(running, { depth: null });
  for (let i = 0; i < running.length; i++) {
    const el = running[i];
    let data = await ec2.describeInstances(el.id);
    const instance = data.Reservations[0].Instances[0];
    ami = instance.ImageId;
    console.log(
      `${i}: ${instance.Tags[0].Value} ${instance.InstanceId} ${
        instance.ImageId
      }`
    );
  }
  console.log(ami);
  const img = await ec2.describeImagesById(ami);
  console.dir(img, { depth: null });
  const snapshot = await ec2.describeSnapshot(img.snapshot);
  console.dir(snapshot, { depth: null });
}
