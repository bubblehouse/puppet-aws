# Install all the dependencies needed for this module to function

class aws::foreman::install inherits aws::foreman {
  class { '::foreman':
    custom_repo => true,
    environment => $aws::foreman::foreman_environment,
    admin_password => $aws::foreman::admin_password,
    server_ssl_key => "/var/lib/puppet/ssl/private_keys/${aws::bootstrap::instance_fqdn}.pem",
    server_ssl_cert => "/var/lib/puppet/ssl/certs/${aws::bootstrap::instance_fqdn}.pem",
  }->
  
  class { '::foreman_proxy':
    custom_repo => true,
    foreman_server_ssl_key => "/var/lib/puppet/ssl/private_keys/${aws::bootstrap::instance_fqdn}.pem",
    foreman_server_ssl_cert => "/var/lib/puppet/ssl/certs/${aws::bootstrap::instance_fqdn}.pem",
    require => [
      Exec['create-puppetmaster-cert'],
      Exec['rm-puppet-conf']
    ]
  }
}