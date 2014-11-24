# == Class: bootstrap
#
# Bootstrap utilities for EC2 and CloudFormation. A set of helper classes,
# functions and facts to aid in creating userdata and cfn-init scripts.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default.
#
# === Examples
#
#  class { "bootstrap":
#    
#  }
#
# === Authors
#
# Phil Christensen <phil@bubblehouse.org>
#
class bootstrap(
  $default_aws_region = 'us-east-1'
){
  include apt
  include staging
  
  File {
    owner => 'root',
    group => 'root',
    mode => '0755'
  }
  
  $instance_name = "${cfn_baseinstancetag}-${ec2_instance_slug}"
  
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

  ensure_packages(["puppet", "git", "bundler", "python-pip", "augeas-tools", "tree", "ccze", "update-notifier-common"], {
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

  package { "awscli":
    ensure => latest,
    source => "https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz",
    provider => pip,
    require => Package['python-pip']
  }
  
  staging::deploy { "ubuntu-ec2-net-utils.tar.gz":
    source => "https://github.com/ademaria/ubuntu-ec2net/tarball/105e574"
    target => "/usr/src",
    creates => "/usr/src/ubuntu-ec2-net-utils"
  }
  
  staging::file { "jq":
    source => "http://stedolan.github.io/jq/download/linux64/jq"
    target => "/usr/local/bin"
  }
  
  file { "/etc/facter/facts.d/environment.txt":
    ensure => file,
    content => "environment=${environment}",
  }

  exec { "create-instance-tags":
    command => "aws ec2 create-tags --resources ${ec2_instance_id} --tags Key=Name,Value=${instance_name}",
    environment => "AWS_DEFAULT_REGION=${default_aws_region}",
    path => '/usr/local/bin'
  }
  
  exec { "configure-hostname":
    command => "/bin/hostname -b ${instance_name}.${cfn_endpointzone}"
  }
  
  file {
    ['/etc/hostname', '/etc/mailname']:
      ensure => file,
      content => "${instance_name}.${cfn_endpointzone}"
  }
  
  augeas { "/etc/hosts":
    context   => '/files/etc/hosts',
    changes   => [
        "set 1/canonical ${instance_name}.${cfn_endpointzone}",
        "set 1/alias[1] ${instance_name}"
      ]
  }
  
  augeas { "/etc/puppet/puppet.conf":
    context   => '/files/etc/puppet/puppet.conf',
    changes   => [
        "set main/environment ${environment}"
        "rm main/templatedir"
        "set main/waitforcert 30s"
      ]
  }
  
  cron { "puppet-agent":
    command => "/usr/bin/puppet agent --test --environment=${environment} &> /dev/null",
    user    => root,
    minute  => '*/30'
  }
  
  file { "/usr/local/sbin/configure-nat.sh"
    content => join("\n", [
      '#!/bin/bash -x',
      'PATH=/usr/sbin:/sbin:/usr/bin:/bin',
      'INTERFACE=eth1',
      'ETH_MAC=$(facter macaddress_${INTERFACE})',
      'VPC_CIDR_RANGE=$(facter ec2_network_interfaces_macs_${ETH_MAC}_vpc_ipv4_cidr_block)',
      'sysctl -q -w net.ipv4.ip_forward=1 net.ipv4.conf.${INTERFACE}.send_redirects=0 && (',
      '   iptables -t nat -C POSTROUTING -o ${INTERFACE} -s ${VPC_CIDR_RANGE} -j MASQUERADE 2> /dev/null ||',
      '   iptables -t nat -A POSTROUTING -o ${INTERFACE} -s ${VPC_CIDR_RANGE} -j MASQUERADE ) || exit',
      'sysctl net.ipv4.ip_forward net.ipv4.conf.${INTERFACE}.send_redirects',
      'iptables -n -t nat -L POSTROUTING'
    ]),
    mode => "0755"
  }
}
