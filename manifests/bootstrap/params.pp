class aws::bootstrap::params {
  $instance_name = "${cfn_baseinstancetag}-${ec2_instance_slug}"
  $instance_fqdn = "${instance_name}.${cfn_endpointzone}"
  $is_nat = false
  $nat_interface = 'eth1'
  $nat_cidr_range = nil
  $eni_id = nil
  $eip_allocation_id = nil
  $static_volume_size = 0
  $static_volume_encryption = false
  $static_volume_tag = nil
}