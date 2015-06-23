# Configure the installed packages

class aws::bootstrap::config inherits aws::bootstrap {
  if( ! aws_has_tag($::ec2_instance_id, "Name", $aws::bootstrap::instance_name)){
    aws_create_tag($::ec2_instance_id, "Name", $aws::bootstrap::instance_name)
  }

  file { ["/etc/facter", "/etc/facter/facts.d"]:
    ensure => directory
  }

  if ( $aws::bootstrap::role != nil) {
    file { "/etc/facter/facts.d/role.txt":
      ensure => file,
      content => "role=${aws::bootstrap::role}",
      require => File['/etc/facter/facts.d']
    }
  }

  file { "/etc/facter/facts.d/environment.txt":
    ensure => file,
    content => "environment=${aws::bootstrap::environment}",
    require => File['/etc/facter/facts.d']
  }

  file { "/etc/awslogs-agent.conf":
    ensure => present,
    replace => false,
    content => join([
      "[general]",
      "state_file = /var/awslogs/state/agent-state",
      "",
      "[/var/log/syslog]",
      "file = /var/log/syslog",
      "log_group_name = /var/log/syslog",
      "log_stream_name = {instance_id}",
      "datetime_format = %b %d %H:%M:%S",
      "",
      "[/var/log/auth.log]",
      "file = /var/log/auth.log",
      "log_group_name = /var/log/auth.log",
      "log_stream_name = {instance_id}",
      "datetime_format = %b %d %H:%M:%S",
      "",
      "[/var/log/cloud-init-output.log]",
      "file = /var/log/cloud-init-output.log",
      "log_group_name = /var/log/cloud-init-output.log",
      "log_stream_name = {instance_id}",
      "datetime_format = %b %d %H:%M:%S\n"
    ], "\n"),
    notify => Service['awslogs']
  }->

  exec { "awslogs-agent-setup":
    command => "/usr/bin/python /opt/staging/aws/awslogs-agent-setup.py -n -r ${::aws_region} -c /etc/awslogs-agent.conf",
    creates => "/etc/init.d/awslogs",
    notify => Service['awslogs']
  }

  service { 'awslogs':
    ensure => running,
    enable => true
  }

  if $::osfamily == "Redhat" and $::operatingsystemrelease =~ /6\.[0-9]/ {
    file_line { 'redhat-hostname-file':
      path  => '/etc/sysconfig/network',
      match => 'HOSTNAME=',
      line  => "HOSTNAME=${aws::bootstrap::instance_fqdn}"
    }

    exec { "configure-hostname":
      command => "/bin/hostname ${aws::bootstrap::instance_fqdn}",
      unless  => "/usr/bin/test \"${aws::bootstrap::instance_fqdn}\" == \"$(/bin/hostname -f)\""
    }
  }
  else {
    exec { "configure-hostname":
      command => "/bin/hostname -b ${aws::bootstrap::instance_fqdn}",
      unless  => "/usr/bin/test \"${aws::bootstrap::instance_fqdn}\" == \"$(/bin/hostname -f)\""
    }
  }

  case $osfamily {
    'Debian' : {
      augeas { "/etc/hosts":
        context   => '/files/etc/hosts',
        changes   => [
            "set 1/canonical ${aws::bootstrap::instance_fqdn}",
            "set 1/alias[1] ${aws::bootstrap::instance_name}"
          ]
      }
    }
    'RedHat': {
      file_line { "/etc/hosts":
        path => "/etc/hosts",
        line => "127.0.1.1 ${aws::bootstrap::instance_fqdn} ${aws::bootstrap::instance_name}"
      }
    }
  }

  file {
    ['/etc/hostname', '/etc/mailname']:
      ensure => file,
      content => "${aws::bootstrap::instance_fqdn}"
  }

  file_line { "/etc/environment":
    path => "/etc/environment",
    line => "AWS_DEFAULT_REGION=${::aws_region}"
  }

  augeas { "base-puppet.conf":
    context   => '/files/etc/puppet/puppet.conf',
    changes   => [
        "set main/environment ${environment}",
        "rm main/templatedir",
        "set main/waitforcert 30s",
        "set main/stringify_facts false"
      ]
  }

  cron { "puppet-agent":
    command => "/usr/bin/puppet agent --test &> /dev/null",
    user    => root,
    minute  => '*/30'
  }

  if($aws::bootstrap::static_volume_size != "0") {
    $cloudwatch_cmd = "/usr/bin/perl /usr/local/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --disk-path=${aws::bootstrap::static_volume_mountpoint} --from-cron"
  }
  else {
    $cloudwatch_cmd = '/usr/bin/perl /usr/local/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --from-cron'
  }

  cron { "cloudwatch":
    command => $cloudwatch_cmd,
    environment => 'PERL_LWP_SSL_VERIFY_HOSTNAME=0',
    user    => root,
    minute  => '*/5'
  }
}
