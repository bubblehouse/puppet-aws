# lib/puppet/type/ec2_security_group.rb
Puppet::Type.newtype(:ec2_security_group) do
  @doc = "Ensure the current EC2 instance is part of a given SG."

  ensurable
  newparam(:group_id) do
    isnamevar
    desc "The AWS security group ID."
    validate do |value|
      unless value =~ /^sg-\w+/
        raise ArgumentError, "%s is not a valid security group ID." % value
      end
    end
  end
end