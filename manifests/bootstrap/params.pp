class aws::bootstrap::params {
  $route53_internal_zone    = nil
  $role                     = "${::cfn_puppetrole}"
  $environment              = "${::cfn_puppetenvironment}"
  $instance_name            = "${hostname}"
  $instance_fqdn            = "${fqdn}"
  $is_nat                   = false
  $nat_cidr_range           = nil
  $eni_interface            = 'eth1'
  $eni_id                   = nil
  $eip_allocation_id        = nil
  $deploy_key_s3_url        = nil
  $static_volume_size       = 0
  $static_volume_encryption = false
  $static_volume_tag        = nil
  $puppetmaster             = false
  $puppetmaster_hostname    = "puppet"
}
