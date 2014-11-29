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
  $is_nat = $aws::bootstrap::params::is_nat,
  $eni_id = $aws::bootstrap::params::eni_id,
  $eip_allocation_id = $aws::bootstrap::params::eip_allocation_id,
  $static_volume_size = $aws::bootstrap::params::static_volume_size,
  $static_volume_encryption = $aws::bootstrap::params::static_volume_encryption,
  $static_volume_tag = $aws::bootstrap::params::static_volume_tag
) inherits aws::bootstrap::params {
  include aws
  
  File {
    owner => 'root',
    group => 'root',
    mode => '0755'
  }
  
  # http://docs.puppetlabs.com/puppet/2.7/reference/lang_containment.html#known-issues
  anchor { 'aws::bootstrap::begin': } ->
  class { '::aws::bootstrap::install': } ->
  class { '::aws::bootstrap::config': } ->
  class { '::aws::bootstrap::resources': } ->
  class { '::aws::bootstrap::attachments': } ->
  class { '::aws::nat': } ->
  anchor { 'aws::end': }
}
