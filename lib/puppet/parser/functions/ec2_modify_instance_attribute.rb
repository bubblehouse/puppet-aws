module Puppet::Parser::Functions
  newfunction(:ec2_modify_instance_attributes) do |args|
    instance_id, attribute, value = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      resp = ec2.modify_instance_attribute(
        instance_id: instance_id,
        attribute: attribute,
        value: value
      )
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      Puppet.send(:err, "Error trying to modify instance attribute: #{e}")
    end
  end
end