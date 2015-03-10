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
#  class { "aws::foreman":
#  
#  }
#
# === Authors
#
# Phil Christensen <phil@bubblehouse.org>
#

class aws::foreman(
  $admin_password = $aws::foreman::params::admin_password,
  $base_module_vendor = $aws::foreman::params::base_module_vendor,
  $base_module_name = $aws::foreman::params::base_module_name,
  $base_module_repo = $aws::foreman::params::base_module_repo,
  $foreman_environment = $aws::foreman::params::foreman_environment,
  $autosign_glob = $aws::foreman::params::autosign_glob
) inherits aws::foreman::params {
  anchor { 'aws::foreman::begin': } ->
  class { '::aws::bootstrap': puppetmaster => true } ->
  class { '::aws::foreman::install': } ->
  class { '::aws::foreman::config': } ->
  anchor { 'aws::foreman::end': }
}
