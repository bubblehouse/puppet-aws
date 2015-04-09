require 'aws-sdk'

Facter.add('asg_name') do
  setcode do
    region = Facter.value(:ec2_placement_availability_zone).chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      resp = ec2.describe_tags(
        filters: [{
          name: "resource-type",
          values: ["instance"],
        }, {
          name: "resource-id",
          values: [Facter.value(:ec2_instance_id)],
        }, {
          name: "key",
          values: ["aws:autoscaling:groupName"],
        }]
      )
      resp[:tags][0][:value]
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      Facter::Core::Logging.warn("Failure in locating Autoscaling group name: #{e}")
      nil
    end
  end
end

