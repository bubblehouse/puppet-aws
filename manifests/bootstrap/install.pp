# Install all the dependencies needed for this module to function

class aws::bootstrap::install inherits aws::bootstrap {
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

  ensure_packages(["puppet", "python-pip", "update-notifier-common",
      "unzip", "libwww-perl", "libcrypt-ssleay-perl"], {
    ensure => installed,
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
  
  staging::deploy { "CloudWatchMonitoringScripts-v1.1.0.zip":
    source => "http://ec2-downloads.s3.amazonaws.com/cloudwatch-samples/CloudWatchMonitoringScripts-v1.1.0.zip",
    target => "/usr/local",
    creates => "/usr/local/aws-scripts-mon"
  }
  
  if($aws::bootstrap::static_volume_size > 0) {
    $cloudwatch_cmd = '/usr/bin/perl /usr/local/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --disk-path=/media/static --from-cron &>> /var/log/cloudwatch-cron.log'
  }
  else {
    $cloudwatch_cmd = '/usr/bin/perl /usr/local/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --from-cron &>> /var/log/cloudwatch-cron.log'
  }
  
  cron { "cloudwatch":
    command => $cloudwatch_cmd,
    user    => root,
    minute  => '*/5'
  }
}