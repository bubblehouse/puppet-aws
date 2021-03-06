# == Class: aws
#
# Bootstrap utilities for EC2 and CloudFormation. A set of helper classes,
# functions and facts to aid in creating userdata and cfn-init scripts.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default.
#
# === Examples
#
#  class { "aws::bootstrap":
#    static_volume_size => 8,
#    static_volume_encryption => false,
#    static_volume_tag => "test-bootstrap"
#  }
#
# === Authors
#
# Phil Christensen <phil@bubblehouse.org>
#

class aws::bootstrap(
  $route53_internal_zone = $aws::bootstrap::params::route53_internal_zone,
  $instance_name = $aws::bootstrap::params::instance_name,
  $instance_fqdn = $aws::bootstrap::params::instance_fqdn,
  $ecs_cluster_name = $aws::bootstrap::params::ecs_cluster_name,
  $ecs_docker_host = $aws::bootstrap::params::ecs_docker_host,
  $ecs_docker_username = $aws::bootstrap::params::ecs_docker_username,
  $ecs_docker_email = $aws::bootstrap::params::ecs_docker_email,
  $ecs_docker_password = $aws::bootstrap::params::ecs_docker_password,
  $is_nat = $aws::bootstrap::params::is_nat,
  $eni_interface = $aws::bootstrap::params::eni_interface,
  $nat_cidr_range = $aws::bootstrap::params::nat_cidr_range,
  $eni_id = $aws::bootstrap::params::eni_id,
  $eip_allocation_id = $aws::bootstrap::params::eip_allocation_id,
  $deploy_key_s3_url = $aws::bootstrap::params::deploy_key_s3_url,
  $static_volume_size = $aws::bootstrap::params::static_volume_size,
  $static_volume_mountpoint = $aws::bootstrap::params::static_volume_mountpoint,
  $static_volume_encryption = $aws::bootstrap::params::static_volume_encryption,
  $static_volume_tag = $aws::bootstrap::params::static_volume_tag,
  $puppetmaster = $aws::bootstrap::params::puppetmaster,
  $puppetmaster_hostname = $aws::bootstrap::params::puppetmaster_hostname,
  $puppetport = $aws::bootstrap::params::puppetport
) inherits aws::bootstrap::params {
  include aws
  
  File {
    owner => 'root',
    group => 'root',
    mode => '0755'
  }
  
  # http://docs.puppetlabs.com/puppet/2.7/reference/lang_containment.html#known-issues
  anchor { 'aws::bootstrap::begin': } ->
  class { '::aws::bootstrap::install': puppetmaster => $puppetmaster } ->
  class { '::aws::bootstrap::config': } ->
  class { '::aws::bootstrap::resources': } ->
  class { '::aws::bootstrap::attachments': }

  if($is_nat){
    class { '::aws::config::nat':
      require => Class['::aws::bootstrap::attachments'],
      before => Anchor['aws::bootstrap::end']
    }
  }
  
  anchor { 'aws::bootstrap::end':
    require => Class['::aws::bootstrap::attachments']
  }
}
