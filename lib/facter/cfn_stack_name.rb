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
          name: "resource-id",
          values: [Facter.value(:ec2_instance_id)],
        }, {
          name: "key",
          values: ["aws:cloudformation:stack-name"],
        }]
      )
      if resp.tags.length == 0
        if File.exist?('/var/lib/cloud/data/cloudformation-stack-name')
          File.open('/var/lib/cloud/data/cloudformation-stack-name', 'r').read
        else
          raise "No tag found, no file at '/var/lib/cloud/data/cloudformation-stack-name'"
        end
      elsif resp.tags.length == 1
        resp[:tags][0][:value]
      else
        raise "More than 2 tags matched the filter. Strictly speaking, this shouldn't happen"
      end
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      Facter::Core::Logging.warn("Failure in cfn_stack_name fact: #{e}")
      nil
    end
  end
end
