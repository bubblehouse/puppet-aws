Puppet::Type.type(:ec2_security_group).provide(:aws) do
    desc "EC2 Security Group management via the AWS API."

    def create
      region = Facter.value(:ec2_placement_availability_zone).chop
      instance_id = Facter.value(:ec2_instance_id)
      ec2 = Aws::EC2::Client.new(region:region)
      begin
        current = current_groups
        current.concat([@resource[:group_id]])
        Puppet.send(:info, "Adding security group #{@resource[:group_id]}")
        resp = ec2.modify_instance_attribute(
          instance_id: instance_id,
          groups: current
        )
        Puppet.send(:info, "Create #{resp}")
      rescue Aws::EC2::Errors::ServiceError => e
        # rescues all errors returned by Amazon Elastic Compute Cloud
        Puppet.send(:err, "Error trying to add security group: #{e}")
      end
    end

    def destroy
      region = Facter.value(:ec2_placement_availability_zone).chop
      instance_id = Facter.value(:ec2_instance_id)
      ec2 = Aws::EC2::Client.new(region:region)
      begin
        current = current_groups
        current.delete([@resource[:group_id]])
        Puppet.send(:info, "Removing security group #{@resource[:group_id]}")
        resp = ec2.modify_instance_attribute(
          instance_id: instance_id,
          groups: current
        )
      rescue Aws::EC2::Errors::ServiceError => e
        # rescues all errors returned by Amazon Elastic Compute Cloud
        Puppet.send(:err, "Error trying to remove security group: #{e}")
      end
    end

    def exists?
      begin
        current = current_groups
        current.include? @resource[:group_id]
      rescue Aws::EC2::Errors::ServiceError => e
        # rescues all errors returned by Amazon Elastic Compute Cloud
        Puppet.send(:err, "Error trying to check security group: #{e}")
      end
    end
    
    def current_groups
      region = Facter.value(:ec2_placement_availability_zone).chop
      instance_id = Facter.value(:ec2_instance_id)
      ec2 = Aws::EC2::Client.new(region:region)
      resp = ec2.describe_instance_attribute({
        instance_id: instance_id,
        attribute: "groupSet"
      })
      resp.groups.map{|x| x[:group_id]}
    end
end