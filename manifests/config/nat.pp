class bootstrap::config::nat {
  $iface = "eth1"
  $range = ec2_vpc_cidr($iface)
  
  if($bootstrap::eni_id == nil and $bootstrap::is_nat == true){
    ec2_modify_instance_attribute($ec2_instance_id, 'sourceDestCheck', false)
  }
  
  exec { "sysctl-ip-forward":
    command => "sysctl -q -w net.ipv4.ip_forward=1",
    unless => "test $(sysctl net.ipv4.ip_forward) -eq 1"
  }
  
  exec { "sysctl-send-redirects":
    command => "sysctl -q -w net.ipv4.conf.${iface}.send_redirects=0",
    unless => "test $(sysctl net.ipv4.conf.${iface}.send_redirects) -eq 0"
  }
  
  exec { "iptables-nat-rule":
    command => "iptables -t nat -A POSTROUTING -o ${iface} -s ${range} -j MASQUERADE",
    unless => "iptables -t nat -C POSTROUTING -o ${iface} -s ${range} -j MASQUERADE"
  }
}