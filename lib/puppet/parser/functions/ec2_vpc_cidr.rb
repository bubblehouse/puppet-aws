module Puppet::Parser::Functions
  newfunction(:ec2_vpc_cidr, :type => :rvalue) do |iface|
    mac = lookupvar("macaddress_#{iface}") 
    lookupvar("ec2_network_interfaces_macs_#{mac}_vpc_ipv4_cidr_block")
  end
end