module Puppet::Parser::Functions
  newfunction(:ec2_associate_address) do |args|
    instance_id, allocation_id = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      resp = ec2.associate_address(
        instance_id: instance_id,
        allocation_id: allocation_id,
        allow_reassociation: true
      )
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      function_notice(e)
    end
  end
end