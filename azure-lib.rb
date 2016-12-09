def azureSet(id)
  if id < 5
    ["azure#{id}", 'Developer Program Benefit']
  else
    ["azure#{id}", 'Microsoft Partner Network']
  end
  # if id == 1
  #   ['ppt', 'Microsoft Partner Network']
  # elsif id == 5
  #   ['azure5', 'Microsoft Partner Network']
  # else
  #   ["ntp", 'Developer Program Benefit']
  # end
end

def azureStatus(id)
  resource,subscription = azureSet(id)
  `azure vm list --resource-group #{resource}  --subscription "#{subscription}" | grep azure#{id}`.split[5]
end

def azureIsRunning(id)
    azureStatus(id) == 'running'
end

def azureStart(id)
  resource,subscription = azureSet(id)
  `azure vm start --name azure#{id} --resource-group #{resource} --subscription "#{subscription}"`
end

# use deallocate instead of stop to stop cost counting
def azureStop(id)
  resource,subscription = azureSet(id)
  `azure vm deallocate --name azure#{id} --resource-group #{resource} --subscription "#{subscription}"`
end

def azureGetRunning
    ans = []
    for i in 1..7
        ans << i if azureIsRunning(i)
    end
    ans
end

def azureGetContainers(id)
    `ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  praphan@ppt-azure#{id}.ddns.net docker ps -a`.split("\n")[1..-1]
end

def azureGetLogs(id, container_id)
    `ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  praphan@ppt-azure#{id}.ddns.net docker logs #{container_id}`
end
