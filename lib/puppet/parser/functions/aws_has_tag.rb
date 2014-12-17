module Puppet::Parser::Functions
  newfunction(:aws_has_tag, :type => :rvalue) do |args|
    resource_id, key, value = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      Puppet.send(:debug, "Looking up tag #{key} on #{resource_id}")
      resp = ec2.describe_tags(
        filters: [{
          name: "resource-id",
          values: [resource_id]
        }, {
          name: "key",
          values: [key]
        }]
      )
      resp[:tags].all? { |tag|
        if value != nil
          tag[:value] == value
        end
      }
      false
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      Puppet.send(:err, e)
    end
  end
end