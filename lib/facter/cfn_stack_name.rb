require 'aws-sdk'

# aws ec2 describe-tags --filters  | jq -r '.Tags|.[0]|.Value'
Facter.add('cfn_stack_name') do
  setcode do
    region = Facter.value(:ec2_placement_availability_zone).chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      resp = ec2.describe_tags(
        filters: [{
          name: "resource-type",
          values: ["instance"],
        }, {
          name: "key",
          values: ["aws:cloudformation:stack-name"],
        }]
      )
      resp[:tags][0][:value]
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      function_notice(e)
      nil
    end
  end
end