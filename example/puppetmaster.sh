#cloud-config
mounts:
 - [ /dev/xvdb, /media/ephemeral0, auto, "defaults,nobootwait", "0", "2" ]
 - [ swap, null ]
apt_update: true
apt_sources:
- source: "deb http://apt.puppetlabs.com trusty main"
  keyid: 4BD6EC30
  filename: puppetlabs.list
- source: "deb http://apt.puppetlabs.com trusty dependencies"
  keyid: 4BD6EC30
  filename: puppetlabs.list
packages:
 - puppet
 - bundler
 - git
 - python-pip
 - augeas-tools
 - tree
 - ccze
write_files:
 - path: /root/.ssh/config
   permissions: '0600'
   content: |
     StrictHostKeyChecking no
   owner: root:root
 - path: /root/.ssh/id_rsa
   permissions: '0600'
   encoding: b64
   ################################################
   #                                              #
   #  This key is your deploy key for gitlab.     #
   #  1) Create a key                             #
   #  2) Add it to gitlab                         #
   #  3) cat id_rsa | base64 -w0                  #
   #  4) copy the content of that command         #
   #     after the "content:" in the next line.   #
   #                                              #
   ################################################
   content:  
   owner: root:root
 - path: /etc/puppet/Gemfile
   content: |
     source 'https://rubygems.org'
     gem 'librarian-puppet'
     gem 'aws-sdk', '>=2.0.6.pre'
 - path: /etc/puppet/Puppetfile
   content: |
     forge 'https://forgeapi.puppetlabs.com'     
     mod 'bootstrap-aws',
       :git => 'https://gitlab.auto.aws.logicworks.net/common-libs/puppet-aws.git'
 - path: /etc/puppet/hiera.yaml
   content: |
     ---
     :backends: yaml
     :yaml:
       :datadir: /etc/puppet/hiera.d
     :hierarchy: bootstrap
     :logger: puppet
 - path: /etc/puppet/hiera.d/bootstrap.yaml
   content: |
     ################################################
     #                                              #
     #  Be sure to set the instance name and FQDN   #
     #  in the puppet variables below.              #
     #                                              #
     ################################################
     aws::bootstrap::instance_name: "puppet"
     aws::bootstrap::instance_fqdn: "puppet.demo.local"
     aws::bootstrap::eip_allocation_id: nil
     aws::bootstrap::static_volume_encryption: false
     aws::bootstrap::static_volume_size: 0
     aws::bootstrap::static_volume_tag: static-volume
     aws::bootstrap::is_nat: false
     aws::bootstrap::eni_interface: nil
     aws::bootstrap::nat_cidr_range: nil
     aws::bootstrap::eni_id: nil
     ################################################
     #                                              #
     #  Be sure to set the instance name and FQDN   #
     #  again in the variables here which are used  #
     #  to setup the SSL certificate used by the    #
     #  puppetmaster during it's setup.             #
     #                                              #
     ################################################
     puppet::server::passenger::ssl_cert: "/var/lib/puppet/ssl/certs/puppet.demo.local.pem"
     puppet::server::passenger::ssl_cert_key: "/var/lib/puppet/ssl/private_keys/puppet.demo.local.pem"
     aws::foreman::base_module_vendor: Logicworks
     ################################################
     #                                              #
     #  Set the puppet repository, the root class   #
     #  name for the client module, and the         #
     #  puppet environment you want the             #
     #  puppetmaster to exist within.               #
     #                                              #
     #  demo is used in the example here.           #
     #                                              #
     ################################################
     aws::foreman::base_module_name: demo
     aws::foreman::base_module_repo: ssh://git@gitlab.auto.aws.logicworks.net:44322/client-puppet/demo.git
     aws::foreman::foreman_environment: mgmt-hub
ssh_authorized_keys:
 - ssh-dss AAAAB3NzaC1kc3MAAACBAKrOf+aK/mZRe/TWaovHZvl3JtH1gC7DZn2O7aSjNqIviAdreZuzIDqq+mKOuJck+/zllx8eeNu5UlesR3IFezNRd9RkQXcSQe5K5nRvO++mCexPzjJrlWmFGc23NcmenchWVNg1cDHxQIBrsE7dcRdfXa8hW6THV0IeYAwTkAtLAAAAFQC7ThNKzD0o4vlvArO2JI8dS2wMvwAAAIAeamD3flIglbZeYVre1BPD9GyW7oUJr7yR7Gt0OtFe6aPK5DNzdt1fxlq1Q7zNjb71vb09cQxqrTeSfzp0UacXGMwLx5Oi34nGiOL6zaNZf8gMU2HqqeCJL1OISZ0B8BV4YSNjHPw4pZgJ8kkmOfJNNQDjsnVvZU1cQr9Xv1pqmwAAAIBnOj6bRvPuWkDcTYTqXmrCUzpx3U3lpFS65Ui/VdozlsRyuTuwjpdWDi2Tw3MjK0tDbGBhDc5z98/bKHJijaiczVx1lj2nsz7eAXZhfl3VARGOS3h0ty3pshLPGNED3LptzBlDXRtL1YqCrX2V+BM1Gy8kWD6TN07ypW0MJ/wKCg== root@dosas
runcmd:
 - cd /etc/puppet
 - bundle install
 - export USER=root
 - export HOME=/root/
 - chmod 600 /root/.ssh
 - git config --global http.sslverify false
 - echo n | librarian-puppet init
 - librarian-puppet install --path=/etc/puppet/bootstrap-modules
 - puppet apply --color=false --modulepath=/etc/puppet/bootstrap-modules --execute 'include aws::foreman'
