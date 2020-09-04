def pcGetContainers(host)
  `#{$sshCmd} #{hostCmd(host)} docker ps -a`.split(/\n/)[1..-1]
end

def pcGetLogs(host, container_id)
  `#{$sshCmd} #{hostCmd(host)} docker logs #{container_id}`
end  

def pcRunning?(user, host)
  `#{$sshCmd} #{hostCmd(host)} pwd` == "/Users/#{user}\n"
end

def pcStop(host)
  `#{$sshCmd} #{hostCmd(host)} sudo poweroff`
end
