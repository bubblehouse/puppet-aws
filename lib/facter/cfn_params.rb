require 'aws-sdk'

# aws cloudformation describe-stacks --stack-name $(facter cfn_stack_name)
# | jq '.Stacks|.[0]|.Parameters|map({key: .ParameterKey, value: .ParameterValue})|from_entries'
Facter.add('cfn_params') do
  setcode do
    region = Facter.value(:ec2_placement_availability_zone).chop
    cloudformation = Aws::CloudFormation::Client.new(region:region)
    begin
      resp = cloudformation.describe_stacks(
        stack_name: Facter.value(:cfn_stack_name)
      )
      Hash[resp[:stacks][0][:parameters].collect { |p|
        [p[:parameter_key], p[:parameter_value]]
      }]
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      function_notice(e)
      nil
    end
  end
end