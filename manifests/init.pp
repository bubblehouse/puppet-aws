# == Class: bootstrap
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
#  class { "bootstrap":
#    
#  }
#
# === Authors
#
# Phil Christensen <phil@bubblehouse.org>
#

class bootstrap(
  $access_key_id = $bootstrap::params::access_key_id,
  $secret_access_key = $bootstrap::params::secret_access_key,
  $default_region = $bootstrap::params::default_region
) inherits bootstrap::params {
  include apt
  include staging
  
  File {
    owner => 'root',
    group => 'root',
    mode => '0755'
  }
  
  if($ec2_iam_instance_profile){
    validate_string($ec2_iam_instance_profile)
    notice("Authenticating with profile ${ec2_iam_instance_profile}")
  }
  else {
    validate_string($access_key_id)
    validate_string($secret_access_key)
    notice("Authenticating with access key ${access_key_id}")
  }
  
  validate_string($default_region)

  # http://docs.puppetlabs.com/puppet/2.7/reference/lang_containment.html#known-issues
  anchor { 'bootstrap::begin': } ->
  class { '::bootstrap::install': } ->
  class { '::bootstrap::config': } ->
  anchor { 'bootstrap::end': }
}
