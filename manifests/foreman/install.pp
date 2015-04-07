# Install all the dependencies needed for this module to function

class aws::foreman::install inherits aws::foreman {
  file { ["/etc/puppet/environments/${aws::foreman::foreman_environment}",
          "/etc/puppet/environments/${aws::foreman::foreman_environment}/manifests",
          "/etc/puppet/environments/${aws::foreman::foreman_environment}/modules"]:
    ensure => directory,
    owner => 'puppet',
    group => 'root'
  }
  
  $certname = downcase($aws::bootstrap::instance_fqdn)
  
  class { '::foreman':
    admin_password => $aws::foreman::admin_password,
    servername => $aws::bootstrap::instance_fqdn,
    environment => $aws::foreman::foreman_environment,
    server_ssl_key => "/var/lib/puppet/ssl/private_keys/${certname}.pem",
    server_ssl_cert => "/var/lib/puppet/ssl/certs/${certname}.pem",
    websockets_ssl_key => "/var/lib/puppet/ssl/private_keys/${certname}.pem",
    websockets_ssl_cert => "/var/lib/puppet/ssl/certs/${certname}.pem",
    require => File["/etc/puppet/environments/${aws::foreman::foreman_environment}/modules"]
  }
  
  class { '::foreman_proxy':
    trusted_hosts => [$aws::bootstrap::instance_fqdn],
    registered_name => $aws::bootstrap::instance_fqdn,
    registered_proxy_url => "https://${aws::bootstrap::instance_fqdn}:8443",
    puppet_url => "https://${aws::bootstrap::instance_fqdn}:8140",
    foreman_base_url => "https://${aws::bootstrap::instance_fqdn}",
    ssl_key => "/var/lib/puppet/ssl/private_keys/${certname}.pem",
    ssl_cert => "/var/lib/puppet/ssl/certs/${certname}.pem",
    require => File["/etc/puppet/environments/${aws::foreman::foreman_environment}/modules"]
  }
  
}