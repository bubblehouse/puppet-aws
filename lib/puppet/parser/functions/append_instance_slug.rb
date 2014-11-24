module Puppet::Parser::Functions
  newfunction(:append_instance_slug, :type => :rvalue) do |args|
    prefix, length = *args
    if length == nil
      length = 3
    end
    instance_id = Facter.value(:ec2_instance_id)
    instance_id[2,length]
  end
end
