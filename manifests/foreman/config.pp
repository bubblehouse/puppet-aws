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

  exec { "update-autosign":
    command => "/bin/echo '${aws::foreman::autosign_glob}' > /etc/puppet/autosign.conf",
    onlyif => '/usr/bin/test "$(cat /etc/puppet/autosign.conf)" == ""'
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
    command => "/bin/echo n | /usr/local/bin/librarian-puppet init",
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
    command => "/usr/local/bin/librarian-puppet install --verbose",
    cwd => "/etc/puppet",
    environment => [
      "USER=root",
      "HOME=/root/"
    ],
    refreshonly => true
  }

  exec { 'apipie-cache':
    command => 'foreman-rake apipie:cache',
    path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    user => 'root',
    creates => '/var/lib/foreman/public/apipie-cache',
    requires => Package['ruby-hammer-cli-foreman'],
    notify => Exec['create-smart-proxy']
  }

  exec { 'create-smart-proxy':
    command => "hammer proxy create --name ${aws::bootstrap::instance_fqdn} --url https://${aws::bootstrap::instance_fqdn}:8443",
    refreshonly => true,
    path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  }
}
