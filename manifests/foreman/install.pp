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
  }
  
  class { '::foreman':
    environment => $aws::foreman::foreman_environment,
    admin_password => $aws::foreman::admin_password
  }
}