require 'json'

module Puppet::Parser::Functions
  newfunction(:ec2_interface_attached, :type => :rvalue) do |args|
    instance_id, interface_id, device_index = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      Puppet.send(:notice, "Getting #{interface_id} attachment info")
      resp = ec2.describe_network_interfaces(
        filters: [{
          name: "attachment.instance-id",
          values: [instance_id]
        }, {
          name: "network-interface-id",
          values: [interface_id]
        }, {
          name: "attachment.device-index",
          values: [device_index]
        }]
      )
      if(resp[:network_interfaces].count > 0)
        Puppet.send(:notice, "ENI #{resp[:network_interfaces][0][:network_interface_id]} is attached to #{device_index} on #{instance_id}")
        true
      else
        Puppet.send(:notice, "ENI #{interface_id} is not attached to #{device_index} on #{instance_id}")
        false
      end
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      Puppet.send(:err, "Error trying to check interface association: #{e}")
    end
  end
end