module Puppet::Parser::Functions
  newfunction(:ec2_attach_volume, :type => :rvalue) do |args|
    instance_id, volume_id, device = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      resp = ec2.attach_volume(
        volume_id: volume_id,
        instance_id: instance_id,
        device: device
      )
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      function_notice(e)
    end
  end
end