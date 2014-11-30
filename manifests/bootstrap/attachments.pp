class aws::bootstrap::attachments inherits aws::bootstrap {
  if($aws::bootstrap::eni_id != nil){
    if(! ec2_interface_attached($ec2_instance_id, $aws::bootstrap::eni_id, 1)){
      ec2_attach_network_interface($ec2_instance_id, $aws::bootstrap::eni_id, 1)
    }
  }
  
  if($aws::bootstrap::eip_allocation_id != nil){
    ec2_associate_address($ec2_instance_id, $aws::bootstrap::eip_allocation_id)
  }

  if($aws::bootstrap::static_volume_size > 0){
    if(! ec2_volume_attached($ec2_instance_id, $aws::bootstrap::resources::volume_id, "/dev/sdf")){
      ec2_attach_volume($ec2_instance_id, $aws::bootstrap::resources::volume_id, "/dev/sdf")
    }
    
    if($existing_volume_id == ""){
      exec { "mkfs":
        command => "/sbin/mkfs.ext4 /dev/xvdf",
        unless => "/sbin/blkid /dev/xvdf",
        before => Mount["/media/static"]
      }
    }
    
    file { "/media/static":
      ensure => directory
    }
    
    mount { "/media/static":
      ensure => mounted,
      atboot => yes,
      device => "/dev/xvdf",
      fstype => auto,
      options => "defaults,nobootwait,nofail",
      dump => 0,
      pass => 2
    }
  }
}