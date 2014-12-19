# Install all the dependencies needed for this module to function

class aws::foreman::install inherits aws::foreman {
  class { '::foreman':
    environment => $aws::foreman::foreman_environment,
    admin_password => $aws::foreman::admin_password
  }
}