# Configure the installed packages

class aws::bootstrap::config inherits aws::bootstrap {
  ec2_create_tag($ec2_instance_id, "Name", $aws::bootstrap::instance_name)
  
  exec { "configure-hostname":
    command => "/bin/hostname -b ${aws::bootstrap::instance_fqdn}"
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
      content => "${aws::bootstrap::instance_fqdn}"
  }
  
  file_line { "/etc/environment":
    path => "/etc/environment",
    line => "AWS_DEFAULT_REGION=${aws_region}"
  }
  
  augeas { "/etc/hosts":
    context   => '/files/etc/hosts',
    changes   => [
        "set 1/canonical ${aws::bootstrap::instance_fqdn}",
        "set 1/alias[1] ${aws::bootstrap::instance_name}"
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
