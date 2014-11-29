class aws(
  $bootstrap => false
){
  if("${ec2_instance_id}" == "") {
    fail("Can't find EC2 instance ID fact, something is wrong.")
  }

  include apt
  include staging

  # http://docs.puppetlabs.com/puppet/2.7/reference/lang_containment.html#known-issues
  anchor { 'aws::begin': } ->
  class { '::aws::install': } ->
  class { '::aws::config': }
  
  if($bootstrap){
    class { '::aws::bootstrap':
      require => Class['::aws::config'],
      before => Anchor['aws::end']
    }
  }
  
  anchor { 'aws::end':
    require => Class['::aws::config']
  }
}