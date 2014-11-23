Facter.add('cfn_stack_name') do
  setcode do
    Facter::Core::Execution.exec("/usr/local/bin/aws ec2 describe-tags --filters Name=resource-type,Values=instance Name=key,Values=aws:cloudformation:stack-name | jq -r '.Tags|.[0]|.Value'")
  end
end

Facter.add('cfn_params') do
  setcode do
    Facter::Core::Execution.exec("aws cloudformation describe-stacks --stack-name $() | jq '.Stacks|.[0]|.Parameters|map({key: .ParameterKey, value: .ParameterValue})|from_entries'")
  end
end