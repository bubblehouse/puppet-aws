class aws::bootstrap::params {
  $is_nat = false
  $eni_id = nil
  $eip_allocation_id = nil
  $static_volume_size = 8
  $static_volume_encryption = false
  $static_volume_tag = "static-storage"
}