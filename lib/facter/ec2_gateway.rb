require 'json'
require 'ipaddr'

Facter.add('ec2_gateway') do
  setcode do
    gateways = {}
    metadata = Facter.value(:ec2_metadata)
    interfaces = metadata["network"]["interfaces"]["macs"]
    macs = interfaces.keys
    macs.each{|mac|
      gateways["eth#{interfaces[mac]["device-number"]}".to_s] = IPAddr.new(interfaces[mac]["subnet-ipv4-cidr-block"]).succ.to_s
    }
    gateways
  end
end

