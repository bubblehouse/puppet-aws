class aws::bootstrap::attachments inherits aws::bootstrap {
  if($aws::eni_id != nil){
    ec2_attach_network_interface($ec2_instance_id, $aws::eni_id, 1)
  }
  
  if($aws::eip_allocation_id != nil){
    ec2_associate_address($ec2_instance_id, $aws::eip_allocation_id)
  }

  if($aws::static_volume_size > 0){
    ec2_attach_volume($ec2_instance_id, $aws::aws::resources::volume_id, "/dev/sdf")
    
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