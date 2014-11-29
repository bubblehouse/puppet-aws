class aws::bootstrap::resources {
  if($aws::bootstrap::static_volume_size > 0){
    $existing_volume_id = ec2_detect_volume($aws::bootstrap::static_volume_tag, $ec2_placement_availability_zone)
    if($existing_volume_id == nil){
      $volume_id = ec2_create_volume($aws::bootstrap::static_volume_size, $aws::bootstrap::static_volume_encryption)
      ec2_create_tag($volume_id, "Name", $aws::bootstrap::static_volume_tag)
    }
    else{
      $volume_id = $existing_volume_id
    }
  }
}