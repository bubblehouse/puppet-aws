# Install all the dependencies needed for this module to function

class aws::install inherits aws {
  include aws::install::ec2netutils
  
  apt::source {
    'puppetlabs-main':
      location   => 'http://apt.puppetlabs.com/',
      release => 'trusty',
      repos => 'main',
      key => '1054B7A24BD6EC30',
      key_server => 'pgp.mit.edu';
    'puppetlabs-deps':
      location   => 'http://apt.puppetlabs.com/',
      release => 'trusty',
      repos => 'dependencies',
      key => '1054B7A24BD6EC30',
      key_server => 'pgp.mit.edu';
  }

  ensure_packages(["puppet", "python-pip", "update-notifier-common"], {
    ensure => latest,
    require => [
      Apt::Source['puppetlabs-main'],
      Apt::Source['puppetlabs-deps']
    ]
  })
  
  package { "awscli":
    ensure => latest,
    provider => pip,
    require => Package['python-pip']
  }

  staging::file { "jq":
    source => "http://stedolan.github.io/jq/download/linux64/jq",
    target => "/usr/local/bin"
  }
}