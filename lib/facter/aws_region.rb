Facter.add('aws_region') do
  setcode do
    Facter.value(:ec2_placement_availability_zone).chop
  end
end
