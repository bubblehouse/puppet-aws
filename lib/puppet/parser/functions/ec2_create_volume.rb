module Puppet::Parser::Functions
  newfunction(:ec2_create_volume, :type => :rvalue) do |args|
    size, encrypted = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      Puppet.send(:notice, "Creating #{size}GB #{encrypted ? 'encrypted' : ''} volume")
      resp = ec2.create_volume(
        size: size,
        availability_zone: Facter.value(:ec2_placement_availability_zone),
        volume_type: "gp2",
        encrypted: encrypted
      )
      Puppet.send(:notice, "Created #{resp[:volume_id]}, waiting 15s")
      sleep(15)
      resp[:volume_id]
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      Puppet.send(:err, "Error trying to create volume: #{e}")
    end
  end
end