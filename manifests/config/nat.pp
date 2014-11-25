class bootstrap::config::nat {
  $iface = "eth1"
  $mac = inline_template("<%= scope.lookupvar('$macaddress_${iface}') %>")
  $range = inline_template("<%= scope.lookupvar('$ec2_network_interfaces_macs_${mac}_vpc_ipv4_cidr_block') %>")
  
  if($bootstrap::eni_id == nil){
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