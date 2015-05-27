# Configure the installed packages

class aws::foreman::config inherits aws::foreman {
  include foreman::plugin::default_hostgroup

  if ($aws::bootstrap::route53_internal_zone != nil) {
      update_internal_dns($aws::bootstrap::route53_internal_zone, $aws::bootstrap::cfn_baseinstancetag, $aws::bootstrap::instance_name)
  }

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

  file { '/etc/hammer':
    ensure => 'directory'
  }->
  file { '/etc/hammer/cli.modules.d':
    ensure => 'directory'
  }

  exec { 'hammer-gem-install':
    command => 'gem install hammer_cli_foreman',
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    user    => 'root',
    environment => [
      "USER=root",
      "HOME=/root/"
    ],
    creates => '/usr/local/bin/hammer',
    notify  => Exec['apipie-cache']
  }

  file_line {'add-foreman-admin-to-hammer-conf':
    path  => '/var/lib/gems/1.9.1/gems/hammer_cli_foreman-0.2.0/config/foreman.yml',
    match => ":password:",
    line  => "  :password: ${aws::foreman::admin_password}"
  }

  file { '/etc/hammer/cli.modules.d/foreman.yml':
    ensure => link,
    target => '/var/lib/gems/1.9.1/gems/hammer_cli_foreman-0.2.0/config/foreman.yml'
  }

  exec { 'apipie-cache':
    command => 'foreman-rake apipie:cache',
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    user    => 'root',
    creates => '/var/lib/foreman/public/apipie-cache',
    environment => [
      "USER=root",
      "HOME=/root/"
    ],
    require => [
      Exec['hammer-gem-install'],
      Class['foreman::plugin::default_hostgroup'],
      File['/etc/hammer/cli.modules.d/foreman.yml']
    ]
  }

  exec { 'restart-apache-to-get-foreman-up':
    command     => '/etc/init.d/apache2 restart && /bin/sleep 10',
    user        => 'root',
    require     => Exec['apipie-cache'],
    refreshonly => true
  }

  exec { 'create-smart-proxy':
    command     => "hammer -u admin -p ${aws::foreman::admin_password} proxy create --name ${aws::bootstrap::instance_fqdn} --url https://${aws::bootstrap::instance_fqdn}:8443",
    refreshonly => true,
    environment => [
      "USER=root",
      "HOME=/root/"
    ],
    require     => Exec['restart-apache-to-get-foreman-up'],
    notify      => Service['apache2'],
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  }

  exec { 'import-clases-to-smart-proxy':
    command     => "hammer -u admin -p ${aws::foreman::admin_password} proxy import-classes --name ${aws::bootstrap::instance_fqdn}",
    refreshonly => true,
    environment => [
      "USER=root",
      "HOME=/root/"
    ],
    require     => Exec['restart-apache-to-get-foreman-up'],
    notify      => Service['apache2'],
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  }

  exec { 'foreman-settings-force_hostgroup_match':
    command     => "hammer -u admin -p ${aws::foreman::admin_password} settings set --name force_hostgroup_match --value true",
    refreshonly => true,
    environment => [
      "USER=root",
      "HOME=/root/"
    ],
    require     => Exec['restart-apache-to-get-foreman-up'],
    notify      => Service['apache2'],
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  }

  exec { 'foreman-settings-force_hostgroup_match_only_new':
    command     => "hammer -u admin -p ${aws::foreman::admin_password} settings set --name force_hostgroup_match_only_new --value false",
    refreshonly => true,
    environment => [
      "USER=root",
      "HOME=/root/"
    ],
    require     => Exec['restart-apache-to-get-foreman-up'],
    notify      => Service['apache2'],
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  }

  exec { 'foreman-settings-update_environment_from_facts':
    command     => "hammer -u admin -p ${aws::foreman::admin_password} settings set --name update_environment_from_facts --value true",
    refreshonly => true,
    environment => [
      "USER=root",
      "HOME=/root/"
    ],
    require     => Exec['restart-apache-to-get-foreman-up'],
    notify      => Service['apache2'],
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  }

}
