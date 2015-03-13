class aws::config::nat {
  $ec2gatewayeth0 = $aws::bootstrap::ec2_gateway['eth0']

  if ($aws::bootstrap::ec2_gateway['eth1'] == "") {
      $ec2gatewayeth1 = $aws::bootstrap::ec2_gateway['eth0']
  }
  else {
      $ec2gatewayeth1 = $aws::bootstrap::ec2_gateway['eth1']
  }

  if ($aws::bootstrap::route53_internal_zone != nil) {
      vpc_attach_r53_zone($::ec2_vpc, $aws::bootstrap::route53_internal_zone)
  }




  if($aws::bootstrap::eni_id == nil){
    ec2_modify_instance_attribute($::ec2_instance_id, 'sourceDestCheck', false)
  }
  
  package { "iptables-persistent":
    ensure => installed
  }
  
  sysctl { "net.ipv4.ip_forward":
    ensure => present,
    permanent => "yes",
    value => '1',
    notify => Exec['wait-10s-for-ip-forwarding']
  }->
  
  sysctl { "net.ipv4.conf.${aws::bootstrap::eni_interface}.send_redirects":
    ensure => present,
    permanent => "yes",
    value => '0',
    notify => Exec['wait-10s-for-ip-forwarding']
  }->
  
  exec { "iptables-nat-rule":
    command => "/sbin/iptables -t nat -A POSTROUTING -o ${aws::bootstrap::eni_interface} -s ${aws::bootstrap::nat_cidr_range} -j MASQUERADE",
    logoutput => on_failure,
    unless => "/sbin/iptables -t nat -C POSTROUTING -o ${aws::bootstrap::eni_interface} -s ${aws::bootstrap::nat_cidr_range} -j MASQUERADE",
    notify => Exec['iptables-save']
  }

  exec { "iptables-save":
    command => "/sbin/iptables-save > /etc/iptables/rules.v4",
    require => Package['iptables-persistent']
  }
  
  exec { 'wait-10s-for-ip-forwarding':
    command => "/bin/sleep 10",
    refreshonly => true,
    before => Exec['iptables-nat-rule']
  }

}
