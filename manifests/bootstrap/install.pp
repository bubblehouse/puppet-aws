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

  if($puppetmaster){
    exec { "puppetmaster-cert":
      command => "/usr/bin/puppet cert --generate --dns_alt_names localhost,${aws::bootstrap::puppetmaster_hostname},${aws::bootstrap::instance_fqdn} ${aws::bootstrap::instance_fqdn}",
      creates => "/var/lib/puppet/ssl/certs/${aws::bootstrap::instance_fqdn}.pem"
    }
    
    class { '::puppet':
      server => true,
      puppetmaster => $aws::bootstrap::puppetmaster_hostname,
      agent_template => "aws/bootstrap/puppet.erb.conf",
      server_certname => $aws::bootstrap::instance_fqdn,
      server_foreman_url => "https://${aws::bootstrap::instance_fqdn}",
      server_foreman_ssl_cert => "/var/lib/puppet/ssl/certs/${aws::bootstrap::instance_fqdn}.pem",
      server_foreman_ssl_key => "/var/lib/puppet/ssl/private_keys/${aws::bootstrap::instance_fqdn}.pem",
      require => [
        Exec['puppetmaster-cert'],
        Apt::Source['puppetlabs-main'],
        Apt::Source['puppetlabs-deps']
      ]
    }
  }
  else {
    class { '::puppet':
      server => false,
      puppetmaster => $aws::bootstrap::puppetmaster_hostname,
      agent_template => "aws/bootstrap/puppet.erb.conf",
      require => [
        Apt::Source['puppetlabs-main'],
        Apt::Source['puppetlabs-deps']
      ]
    }
  }

  ensure_packages(["python-pip", "update-notifier-common", "ntp",
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
      command => "/usr/local/bin/aws s3 cp ${aws::bootstrap::deploy_key_s3_url} /root/.ssh/id_rsa",
      creates => "/root/.ssh/id_rsa",
      require => Package['awscli']
    }->
    
    file { "/root/.ssh/id_rsa":
      ensure => present,
      replace => false,
      owner => root,
      group => root,
      mode => '0600'
    }
    
    # Some very arbitrary combinations of SSH can fail because of strange MTUs
    # which may be exacerbated by running Git behind a load balancer or proxy.
    #  *  http://serverfault.com/questions/481966/why-is-sshd-hanging-at-server-accepts-key
    #  *  http://superuser.com/questions/568891/ssh-works-in-putty-but-not-terminal
    #  *  http://www.held.org.il/blog/2011/05/the-myterious-case-of-broken-ssh-client-connection-reset-by-peer/
    file { "/root/.ssh/config":
      ensure => file,
      replace => false,
      content => join([
        "Host *",
        "  Cipher aes128-ctr",
        "  MACs hmac-sha1",
        ""
      ], "\n"),
      owner => 'root',
      group => 'root',
      mode => '0600'
    }

    # It would be better if this wasn't hard-coded, as it's Logicworks-specific
    file { "/root/.ssh/known_hosts":
      ensure => present,
      owner => "root",
      group => "root",
      mode => "0600",
    }->

    file_line { "gitlab-host-key-1":
      path => "/root/.ssh/known_hosts",
      line => join(["|1|ogj/x504dwser2whRpQH9gcImww=|bWwftmXEuPZRMhuiIPMsBBwzfy0= ",
                    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzd",
                    "HAyNTYAAABBBKJJwvabinwYXs8U3fqYhHwaRynoLgm7czEKcz2UdQc59H7MO7",
                    "xRGLZAjSfaOYxVEzPpseJz9tiE/U7fTogeCVI="], "")
    }->

    file_line { "gitlab-host-key-2":
      path => "/root/.ssh/known_hosts",
      line => join(["|1|6NrhkkWAapcvxg5rBsopVwfP+ZE=|V1Y6u6l9JZu8NzTTjv7/jT2A1JQ= ",
                    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzd",
                    "HAyNTYAAABBBKJJwvabinwYXs8U3fqYhHwaRynoLgm7czEKcz2UdQc59H7MO7",
                    "xRGLZAjSfaOYxVEzPpseJz9tiE/U7fTogeCVI="], "")
    }
  }

  staging::file { "jq":
    source => "http://stedolan.github.io/jq/download/linux64/jq",
    target => "/usr/local/bin/jq"
  }->
  
  file { "/usr/local/bin/jq":
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0755'
  }
  
  staging::file { "awslogs-agent-setup.py":
    source => "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py"
  }
  
  staging::deploy { "CloudWatchMonitoringScripts-v1.1.0.zip":
    source => "http://ec2-downloads.s3.amazonaws.com/cloudwatch-samples/CloudWatchMonitoringScripts-v1.1.0.zip",
    target => "/usr/local",
    creates => "/usr/local/aws-scripts-mon"
  }
  
  service { "ntp":
    ensure => running,
    enable => true,
    require => Package['ntp']
  }
}