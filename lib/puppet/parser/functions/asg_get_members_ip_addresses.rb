#
# Get the route 53 zone id
# Returns 0 if zone doesn't exist.
# Returns 2 if more than one zone of that name exists.
# Returns the zone_id (/hostedzone/1234567890ABCD) if a single zone exists.
#

module Puppet::Parser::Functions
  newfunction(:asg_get_members_ip_addresses, :type => :rvalue) do |args|
    group_name = *args
    region = Facter.value(:aws_region)

    as = Aws::AutoScaling::Client.new(region:region)
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      resp = as.describe_auto_scaling_groups(auto_scaling_group_names: group_name)
      instances = resp.auto_scaling_groups[0].instances
      instances.select!{|i| i.health_status == "Healthy"}
      instances.map!{|i| Aws::EC2::Instance.new(i.instance_id, client: ec2) }

      instances
    rescue => e
      Puppet.send(:err, "unable to retrieve asg members due to #{e}")
    end
  end
end
