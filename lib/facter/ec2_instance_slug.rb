Facter.add('ec2_instance_slug') do
  setcode do
    instance_id = Facter.value(:ec2_instance_id)
    instance_id[2,3]
  end
end
