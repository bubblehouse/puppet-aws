# Configure the installed packages

class aws::bootstrap::config inherits aws::bootstrap {
  if( ! aws_has_tag($ec2_instance_id, "Name", $aws::bootstrap::instance_name)){
    aws_create_tag($ec2_instance_id, "Name", $aws::bootstrap::instance_name)
  }
  
  file { ["/etc/facter", "/etc/facter/facts.d"]:
    ensure => directory
  }->
  
  file { "/etc/facter/facts.d/environment.txt":
    ensure => file,
    content => "environment=${environment}",
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
    command => "/usr/bin/python /opt/staging/aws/awslogs-agent-setup.py -n -r $aws_region -c /etc/awslogs-agent.conf",
    creates => "/etc/init.d/awslogs",
    notify => Service['awslogs']
  }
  
  service { 'awslogs':
    ensure => running,
    enable => true
  }  
  
  exec { "configure-hostname":
    command => "/bin/hostname -b ${aws::bootstrap::instance_fqdn}",
    unless => "/usr/bin/test \"${aws::bootstrap::instance_fqdn}\" == \"$(/bin/hostname -f)\""
  }->
  
  augeas { "/etc/hosts":
    context   => '/files/etc/hosts',
    changes   => [
        "set 1/canonical ${aws::bootstrap::instance_fqdn}",
        "set 1/alias[1] ${aws::bootstrap::instance_name}"
      ]
  }->
  
  file {
    ['/etc/hostname', '/etc/mailname']:
      ensure => file,
      content => "${aws::bootstrap::instance_fqdn}"
  }
  
  file_line { "/etc/environment":
    path => "/etc/environment",
    line => "AWS_DEFAULT_REGION=${aws_region}"
  }
  
  augeas { "base-puppet.conf":
    context   => '/files/etc/puppet/puppet.conf',
    changes   => [
        "set main/environment ${environment}",
        "set agent/server ${aws::bootstrap::puppetmaster_hostname}",
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
  
  if($aws::bootstrap::static_volume_size > 0) {
    $cloudwatch_cmd = '/usr/bin/perl /usr/local/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --disk-path=/media/static --from-cron'
  }
  else {
    $cloudwatch_cmd = '/usr/bin/perl /usr/local/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --from-cron'
  }
  
  cron { "cloudwatch":
    command => $cloudwatch_cmd,
    user    => root,
    minute  => '*/5'
  }
}
