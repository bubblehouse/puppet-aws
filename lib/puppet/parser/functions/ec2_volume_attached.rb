require 'json'

module Puppet::Parser::Functions
  newfunction(:ec2_volume_attached, :type => :rvalue) do |args|
    instance_id, volume_id, device = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      Puppet.send(:notice, "Getting #{volume_id} attachment info")
      resp = ec2.describe_volumes(
        filters: [{
          name: "attachment.instance-id",
          values: [instance_id]
        }, {
          name: "attachment.device",
          values: [device]
        }, {
          name: "volume-id",
          values: [volume_id]
        }]
      )
      if(resp[:volumes].count > 0)
        Puppet.send(:notice, "Volume #{resp[:volumes][0][:volume_id]} is attached to #{device} on #{instance_id}")
        true
      else
        Puppet.send(:notice, "Volume #{volume_id} is not attached to #{device} on #{instance_id}")
        false
      end
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      Puppet.send(:err, "Error trying to check volume attachment: #{e}")
    end
  end
end