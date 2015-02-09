# Install all the dependencies needed for this module to function

class aws::foreman::install inherits aws::foreman {
  class { '::foreman':
    admin_password => $aws::foreman::admin_password,
    servername => $aws::bootstrap::instance_fqdn,
    environment => $aws::foreman::foreman_environment,
    server_ssl_key => "/var/lib/puppet/ssl/private_keys/${aws::bootstrap::instance_fqdn}.pem",
    server_ssl_cert => "/var/lib/puppet/ssl/certs/${aws::bootstrap::instance_fqdn}.pem",
    websockets_ssl_key => "/var/lib/puppet/ssl/private_keys/${aws::bootstrap::instance_fqdn}.pem",
    websockets_ssl_cert => "/var/lib/puppet/ssl/certs/${aws::bootstrap::instance_fqdn}.pem"
  }

  class { '::foreman_proxy':
    trusted_hosts => [$aws::bootstrap::instance_fqdn],
    registered_name => $aws::bootstrap::instance_fqdn,
    puppet_url => "https://${aws::bootstrap::instance_fqdn}:8140",
    foreman_url => "https://${aws::bootstrap::instance_fqdn}",
    foreman_base_url => "https://${aws::bootstrap::instance_fqdn}",
    registered_proxy_url => "https://${aws::bootstrap::instance_fqdn}:8443",
    ssl_key => "/var/lib/puppet/ssl/private_keys/${aws::bootstrap::instance_fqdn}.pem",
    ssl_cert => "/var/lib/puppet/ssl/certs/${aws::bootstrap::instance_fqdn}.pem"
  }
}