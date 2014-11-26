# Configure the installed packages

class bootstrap::config inherits bootstrap {
  $instance_name = "${cfn_baseinstancetag}-${ec2_instance_slug}"
  $instance_fqdn = "${instance_name}.${cfn_endpointzone}"
  
  # create_tags($ec2_instance_id, "Name", $instance_name)
  
  exec { "configure-hostname":
    command => "/bin/hostname -b ${instance_fqdn}"
  }
  
  file { ["/etc/facter", "/etc/facter/facts.d"]:
    ensure => directory
  }->
  
  file { "/etc/facter/facts.d/environment.txt":
    ensure => file,
    content => "environment=${environment}",
  }

  file {
    ['/etc/hostname', '/etc/mailname']:
      ensure => file,
      content => "${instance_fqdn}"
  }
  
  file_line { "/etc/environment":
    path => "/etc/environment",
    line => "AWS_DEFAULT_REGION=${aws_region}"
  }
  
  augeas { "/etc/hosts":
    context   => '/files/etc/hosts',
    changes   => [
        "set 1/canonical ${instance_fqdn}",
        "set 1/alias[1] ${instance_name}"
      ]
  }
  
  augeas { "/etc/puppet/puppet.conf":
    context   => '/files/etc/puppet/puppet.conf',
    changes   => [
        "set main/environment ${environment}",
        "rm main/templatedir",
        "set main/waitforcert 30s"
      ]
  }
  
  cron { "puppet-agent":
    command => "/usr/bin/puppet agent --test &> /dev/null",
    user    => root,
    minute  => '*/30'
  }
}
