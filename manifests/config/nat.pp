class aws::config::nat {
  $iface = "eth1"
  
  validate_hash($ec2_metadata)
  $range = $ec2_metadata['network']['interfaces']['macs']["${macaddress_eth1}"]['vpc-ipv4-cidr-block']
  
  if($aws::bootstrap::eni_id == nil and $aws::bootstrap::is_nat == true){
    ec2_modify_instance_attribute($ec2_instance_id, 'sourceDestCheck', false)
  }
  
  exec { "sysctl-ip-forward":
    command => "/sbin/sysctl -q -w net.ipv4.ip_forward=1",
    unless => "/usr/bin/test $(/sbin/sysctl -n net.ipv4.ip_forward) -eq 1",
    notify => Exec['wait-10s']
  }->

  exec { "sysctl-send-redirects":
    command => "/sbin/sysctl -q -w net.ipv4.conf.${iface}.send_redirects=0",
    unless => "/usr/bin/test $(/sbin/sysctl -n net.ipv4.conf.${iface}.send_redirects) -eq 0",
    notify => Exec['wait-10s']
  }->

  exec { "iptables-nat-rule":
    command => "/sbin/iptables -t nat -A POSTROUTING -o ${iface} -s ${range} -j MASQUERADE",
    logoutput => on_failure,
    unless => "/sbin/iptables -t nat -C POSTROUTING -o ${iface} -s ${range} -j MASQUERADE"
  }
  
  exec { 'wait-10s':
    command => "/bin/sleep 10",
    refreshonly => true,
    before => Exec['iptables-nat-rule']
  }
}