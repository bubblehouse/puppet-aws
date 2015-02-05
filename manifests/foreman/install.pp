# Install all the dependencies needed for this module to function

class aws::foreman::install inherits aws::foreman {
  class { '::foreman':
    servername => $aws::bootstrap::instance_fqdn,
    lower_fqdn => downcase($aws::bootstrap::instance_fqdn),
    environment => $aws::foreman::foreman_environment,
    admin_password => $aws::foreman::admin_password
  }

  class { '::foreman_proxy':
    ssl_key => "/var/lib/puppet/ssl/private_keys/${aws::bootstrap::instance_fqdn}.pem",
    ssl_cert => "/var/lib/puppet/ssl/certs/${aws::bootstrap::instance_fqdn}.pem",
    puppet_url => "https://${aws::bootstrap::instance_fqdn}:8140",
    foreman_base_url => "https://${aws::bootstrap::instance_fqdn}",
    registered_name => $aws::bootstrap::instance_fqdn,
    registered_proxy_url => "https://${aws::bootstrap::instance_fqdn}:8443"
  }
}