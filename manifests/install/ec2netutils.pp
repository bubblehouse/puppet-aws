class bootstrap::install::ec2netutils {
  $path = "/usr/src/ademaria-ubuntu-ec2net-105e574/"
  
  staging::deploy { "ubuntu-ec2-net-utils.tar.gz":
    source => "https://github.com/ademaria/ubuntu-ec2net/tarball/105e574",
    target => "/usr/src",
    creates => $path
  }->
  
  file { 
    "/etc/udev/rules.d/53-ec2-network-interfaces.rules":
      ensure => file,
      source => "${path}/53-ec2-network-interfaces.rules";
    "/etc/udev/rules.d/75-persistent-net-generator.rules":
      ensure => file,
      source => "${path}/75-persistent-net-generator.rules";
    "/etc/dhcp/dhclient-exit-hooks.d/ec2dhcp":
      ensure => file,
      source => "${path}/ec2dhcp";
    "/etc/network/ec2net-functions":
      ensure => file,
      source => "${path}/ec2net-functions";
    "/etc/network/ec2net.hotplug":
      ensure => file,
      source => "${path}/ec2net.hotplug",
      mode => "0744";
  }
}