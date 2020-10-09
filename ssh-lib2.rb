$sshCmd = 'ssh -q  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no'

def hostCmd(host)
  if host.downcase.include? 'azure'
    "praphan@ppt-#{host}.ddns.net"
  elsif host.downcase == 'localhost'
    "localhost -p 2625"
  elsif host.downcase == 'pc'
    "praphan@ppt-pc.ddns.net -p 2625"
  elsif host.downcase == 'mac'
    "praphan@ppt-mac.ddns.net -p 2625"
  elsif host.downcase == 'macppt'
    "praphan@ppt-macppt.ddns.net"
  elsif host.downcase == 'play'
    "praphan@ppt-macppt.ddns.net"
  elsif host.downcase == 'macntp'
    "nattaya@ppt-macntp.ddns.net"
  else
    "-i ~/Dropbox/booking/Docker/ntp.pem ubuntu@ppt#{host.downcase.gsub('aws','')}.ddns.net"
  end
end

def d_stop(host)
  dockerStopCmd = "'docker stop $(docker ps -qa) ; docker rm $(docker ps -qa)'"
  stopTmux = 'tmux kill-server'
  
  `#{$sshCmd} #{hostCmd(host)} #{dockerStopCmd}`
  `#{$sshCmd} #{hostCmd(host)} #{stopTmux}`  
end

def tmuxNewSession(session)
  "tmux new-session -d -s t#{session}"
end

def tmuxSession(session)
  "tmux send-keys -t t#{session}"
end
