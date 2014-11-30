module Puppet::Parser::Functions
  newfunction(:aws_create_tag) do |args|
    resource_id, key, value = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      Puppet.send(:notice, "Creating tag #{key} as #{value} on #{resource_id}")
      resp = ec2.create_tags(
        resources: [resource_id],
        tags: [{
          key: key,
          value: value
        }]
      )
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      Puppet.send(:err, e)
    end
  end
end