# Configure the installed packages

class aws::foreman::config inherits aws::foreman {
  include foreman::plugin::default_hostgroup
  
  augeas { "foreman-puppet.conf":
    context   => '/files/etc/puppet/puppet.conf',
    changes   => [
      "set agent/environment ${aws::foreman::foreman_environment}",
      "set master/external_nodes \"/etc/puppet/node.rb --no-environment\"",
    ],
    notify => Service['apache2']
  }
  
  file { "/etc/puppet/autosign.conf":
    ensure => file,
    content => "*",
    owner => 'root',
    group => 'root',
    mode => '0644',
    notify => Service['apache2']
  }
}