module Puppet::Parser::Functions
  newfunction(:ec2_create_tag) do |args|
    resource_id, key, value = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      resp = ec2.create_tags(
        resources: [resource_id],
        tags: [{
          key: key,
          value: value
        }]
      )
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      function_notice(e)
    end
  end
end