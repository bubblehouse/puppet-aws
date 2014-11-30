module Puppet::Parser::Functions
  newfunction(:ec2_vpc_cidr, :type => :rvalue) do |iface|
    Puppet.send(:notice, "Finding MAC for #{iface}")
    mac = lookupvar("macaddress_#{iface}") 
    Puppet.send(:notice, "Finding CIDR block for #{mac} with fact ec2_network_interfaces_macs_#{mac}_vpc_ipv4_cidr_block")
    lookupvar("ec2_network_interfaces_macs_#{mac}_vpc_ipv4_cidr_block")
  end
end