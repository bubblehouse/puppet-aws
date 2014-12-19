# Install all the dependencies needed for this module to function

class aws::foreman::install inherits aws::foreman {
  exec { "create-puppetmaster-cert":
    command => "/usr/bin/puppet cert generate ${aws::bootstrap::instance_fqdn}",
    creates => "/var/lib/puppet/ssl/certs/${aws::bootstrap::instance_fqdn}.pem"
  }

  class { '::foreman':
    environment => $aws::foreman::foreman_environment,
    admin_password => $aws::foreman::admin_password,
    server_ssl_cert => "/var/lib/puppet/ssl/certs/${aws::bootstrap::instance_fqdn}.pem",
    require => Exec['create-puppetmaster-cert']
  }
}