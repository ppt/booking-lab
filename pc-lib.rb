def pcGetContainers()
  `#{$sshCmd} #{hostCmd('pc')} docker ps -a`.split(/\n/)[1..-1]
end

def pcGetLogs(container_id)
  `#{$sshCmd} #{hostCmd('pc')} docker logs #{container_id}`
end  

def pcRunning?()
  `#{$sshCmd} #{hostCmd('pc')} pwd` =~ /^\/home\/praphan/
end

def pcStop()
  `#{$sshCmd} #{hostCmd('pc')} sudo poweroff`
end
