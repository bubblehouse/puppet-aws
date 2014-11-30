module Puppet::Parser::Functions
  newfunction(:ec2_attach_network_interface) do |args|
    instance_id, interface_id, index = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      Puppet.send(:notice, "Attaching #{instance_id} to #{instance_id} on device index #{index}")
      resp = ec2.attach_network_interface(
        network_interface_id: interface_id,
        instance_id: instance_id,
        device_index: index
      )
      Puppet.send(:notice, "Created #{resp[:attachment_id]}, waiting 15s")
      sleep(15)
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      Puppet.send(:err, "Error trying to attach ENI: #{e}")
    end
  end
end