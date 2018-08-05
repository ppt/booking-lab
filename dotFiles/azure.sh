function azure-set {
  name=azure$(echo $1)
  resource=azure$(echo $1)
  if [ $1 -gt 4 ]
  then
    subscription="Microsoft Partner Network"
  else
    subscription="Developer Program Benefit"
  fi
}

function azure-status {
  if [ $# -eq 0 ]
  then
    for i in {1..6..1}
    do
      azure-set $i
      echo azure$i $(azure vm list --resource-group $(echo $resource)  --subscription "$(echo $subscription)" | grep $(echo $name) | ruby -e 'puts $<.read.split[5]')
    done
  else
    azure-set $1
    azure vm list --resource-group $(echo $resource)  --subscription "$(echo $subscription)" | grep $(echo $name) | ruby -e 'puts $<.read.split[5]'
  fi

}

function azure-start {
  azure-set $1
  azure vm start --name $(echo $name) --resource-group $(echo $resource) --subscription "$(echo $subscription)"
}

function azure-stop {
  azure-set $1
  azure vm deallocate --name $(echo $name) --resource-group $(echo $resource) --subscription "$(echo $subscription)"
}
