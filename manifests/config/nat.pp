class aws::config::nat {
  if($aws::bootstrap::eni_id == nil){
    ec2_modify_instance_attribute($ec2_instance_id, 'sourceDestCheck', false)
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
    before => Exec['iptables-nat-rule'],
    notify => File['/etc/network/interfaces.d/eth0.conf']
  }
 
  $ec2gatewayeth0 = $aws::bootstrap::ec2_gateway['eth0']
  $ec2gatewayeth1 = $aws::bootstrap::ec2_gateway['eth1']

  file { '/etc/network/interfaces.d/eth0.cfg':
    ensure  => file,
    content => join([
      'auto eth0',
      'iface eth0 inet dhcp',
      "post-up ip route add default via ${ec2gatewayeth0} dev eth0 table 10001",
      "post-up ip route add default via ${ec2gatewayeth0} dev eth0 metric 10001",
    ], "\n"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => File['/etc/network/interfaces.d/eth1.cfg'] 
  }
  
  file { '/etc/network/interfaces.d/eth1.cfg':
    ensure  => file,
    content => join([
      'auto eth1',
      'iface eth1 inet dhcp',
      "post-up ip route add default via ${ec2gatewayeth1} dev eth1 table 0",
      "post-up ip route add default via ${ec2gatewayeth1} dev eth1 metric 0",
    ], "\n"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644'
  }
}
