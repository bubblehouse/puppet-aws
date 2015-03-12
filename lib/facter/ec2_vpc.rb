require 'ipaddr'

Facter.add('ec2_vpc_id') do
  setcode do
    begin
      gateways = {}
      metadata = Facter.value(:ec2_metadata)
      metadata["network"]["interfaces"]["macs"].first["vpc-id"]
    rescue e
      Facter::Core::Logging.warn("Failure in ec2_vpc fact: #{e}")
    end
  end
end

