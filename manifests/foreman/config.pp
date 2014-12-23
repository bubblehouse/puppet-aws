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
  
  file { "/etc/puppet/Puppetfile":
    ensure => file,
    content => join([
      "# Install ${aws::foreman::base_module_vendor}-${aws::foreman::base_module_name}",
      "forge 'https://forgeapi.puppetlabs.com'",
      "",
      "mod '${aws::foreman::base_module_vendor}-${aws::foreman::base_module_name}',",
      "  :git => '${aws::foreman::base_module_repo}'"
    ], "\n"),
    owner => 'root', 
    group => 'root', 
    mode => '0644'
  }

  file { "/etc/puppet/Gemfile":
    ensure => file,
    content => join([
      "# Dependencies for ${aws::foreman::base_module_vendor}-${aws::foreman::base_module_name}",
      "source 'https://rubygems.org'",
      "",
      "gem 'librarian-puppet'",
      "gem 'aws-sdk', '>=2.0.6.pre'"
    ], "\n"),
    owner => 'root', 
    group => 'root', 
    mode => '0644',
    notify => Exec['clear-old-librarian']
  }
  
  exec { "clear-old-librarian":
    command => "/bin/rm -rf .tmp .librarian Puppetfile.lock Gemfile.lock",
    cwd => "/etc/puppet",
    refreshonly => true,
    notify => Exec['librarian-init']
  }

  exec { "librarian-bundle-install":
    command => "/usr/bin/bundle install",
    cwd => "/etc/puppet",
    creates => "/usr/local/bin/librarian-puppet",
  }
  
  exec { "librarian-init":
    command => "echo n | /usr/local/bin/librarian-puppet init",
    cwd => "/etc/puppet",
    environment => [
      "USER=root",
      "HOME=/root/"
    ],
    refreshonly => true,
    require => Exec['librarian-bundle-install'],
    notify => Exec['librarian-install']
  }
  
  exec { "librarian-install":
    command => "/usr/local/bin/librarian-puppet install",
    cwd => "/etc/puppet",
    refreshonly => true
  }
}
