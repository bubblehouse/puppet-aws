class aws::bootstrap::attachments inherits aws::bootstrap {
  if($aws::bootstrap::eni_id != nil){
    if(! ec2_interface_attached($::ec2_instance_id, $aws::bootstrap::eni_id, 1)){
      ec2_attach_network_interface($::ec2_instance_id, $aws::bootstrap::eni_id, 1)
    }
    
    exec { "ec2net.hotplug":
      command => "/bin/bash -x /etc/network/ec2net.hotplug ; dhclient ${aws::bootstrap::eni_interface}",
      unless => "/sbin/ifconfig ${aws::bootstrap::eni_interface} | /bin/grep 'inet addr'",
      environment => [
        "ACTION=add",
        "INTERFACE=${aws::bootstrap::eni_interface}"
      ],
      notify => [
        Service['ssh'],
        Exec['force-ifup']
      ]
    }
    
    exec { "force-ifup":
      command => "/sbin/ifup --force ${aws::bootstrap::eni_interface}",
      refreshonly => true,
      notify => Exec['wait-5s-for-interface']
    }
    
    exec { 'wait-5s-for-interface':
      command => "/bin/sleep 5",
      refreshonly => true
    }

    if($aws::bootstrap::is_nat){
      exec { "del-default-gw-eth0":
        command => "/sbin/ip route del default dev eth0",
        refreshonly => true,
        require => Exec['wait-5s-for-interface'],
        subscribe => Exec["ec2net.hotplug"]
      }
    }
  }
  
  if($aws::bootstrap::eip_allocation_id != nil){
    ec2_associate_address($::ec2_instance_id, $aws::bootstrap::eip_allocation_id)
  }

  if( $aws::bootstrap::static_volume_size != "0" ){
    if(! ec2_volume_attached($::ec2_instance_id, $aws::bootstrap::resources::volume_id, "/dev/sdf")){
      ec2_attach_volume($::ec2_instance_id, $aws::bootstrap::resources::volume_id, "/dev/sdf")
    }
    
    if($aws::bootstrap::resources::existing_volume_id == ""){
      exec { "mkfs":
        command => "/sbin/mkfs.ext4 /dev/xvdf",
        unless => "/sbin/blkid /dev/xvdf",
        before => Mount[$aws::bootstrap::static_volume_mountpoint]
      }
    }
    
    mount { $aws::bootstrap::static_volume_mountpoint:
      ensure => mounted,
      atboot => yes,
      device => "/dev/xvdf",
      fstype => auto,
      options => $osfamily ? {
        'RedHat' => "defaults,nofail",
        default => "defaults,nobootwait,nofail"
      },
      dump => 0,
      pass => 2
    }
  }
}
