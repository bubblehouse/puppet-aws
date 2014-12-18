# Install all the dependencies needed for this module to function

class aws::foreman::install inherits aws::foreman {
  apt::source {
    'foreman-trusty':
      location   => 'http://deb.theforeman.org/',
      release => 'trusty',
      repos => '1.7',
      key => 'B3484CB71AA043B8',
      key_server => 'pgp.mit.edu';
    'foreman-plugins':
      location   => 'http://deb.theforeman.org/',
      release => 'plugins',
      repos => '1.7',
      key => 'B3484CB71AA043B8',
      key_server => 'pgp.mit.edu';
  }->

  package { "foreman-installer":
    ensure => installed
  }->
  
  exec { "foreman-installer":
    command => join([
      "/usr/sbin/foreman-installer",
      " --foreman-environment=${aws::foreman::foreman_environment}",
      " --foreman-admin-password=${aws::foreman::admin_password}",
      " --enable-foreman-plugin-default-hostgroup"
    ], ""),
    creates => "/etc/foreman"
  }
}