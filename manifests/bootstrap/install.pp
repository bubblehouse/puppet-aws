# Install all the dependencies needed for this module to function

class aws::bootstrap::install(
  $puppetmaster = false
) inherits aws::bootstrap {
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

  class { '::puppet':
    server => $puppetmaster,
    require => [
      Apt::Source['puppetlabs-main'],
      Apt::Source['puppetlabs-deps']
    ]
  }

  ensure_packages(["python-pip", "update-notifier-common",
      "unzip", "libwww-perl", "libcrypt-ssleay-perl", "libswitch-perl"], {
    ensure => installed
  })
  
  package { "awscli":
    ensure => latest,
    provider => pip,
    require => Package['python-pip']
  }

  if($aws::bootstrap::deploy_key_s3_url != nil){
    exec { "deploy-key":
      command => "/usr/local/bin/aws s3 cp $aws::bootstrap::deploy_key_s3_url /root/.ssh/id_rsa",
      creates => "/root/.ssh/id_rsa",
      require => Package['awscli']
    }
  }

  staging::file { "jq":
    source => "http://stedolan.github.io/jq/download/linux64/jq",
    target => "/usr/local/bin"
  }
  
  staging::file { "awslogs-agent-setup.py":
    source => "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py"
  }
  
  staging::deploy { "CloudWatchMonitoringScripts-v1.1.0.zip":
    source => "http://ec2-downloads.s3.amazonaws.com/cloudwatch-samples/CloudWatchMonitoringScripts-v1.1.0.zip",
    target => "/usr/local",
    creates => "/usr/local/aws-scripts-mon"
  }
}