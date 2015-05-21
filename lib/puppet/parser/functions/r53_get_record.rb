#
# Get a route53 record.
# Returns 0 if record doesn't exist.
# Returns 2 if more than one record of that name exists.
# Returns 3 if it's unable to retrieve the record.
# Returns the record_id hash otherwise.
#

module Puppet::Parser::Functions
  newfunction(:r53_get_record, :type => :rvalue) do |args|
    zone_id, name, type = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    r53 = Aws::Route53::Client.new(region:region)
    begin
      r53_record = r53.list_resource_record_sets(hosted_zone_id: zone_id, start_record_name: name, start_record_type: type)[:resource_record_sets].select{|rec| 
        (rec[:name] =~ /^#{name}/) and 
        (rec[:type] == type ) 
      }

      if r53_record.count == 0
        Puppet.send(:debug, "Unable to locate record #{name} of type #{type} in zone #{zone_id}.")
        r53_record = {:result => 1}
      elsif r53_record.count == 1
        Puppet.send(:debug, "Located record #{name} of type #{type} in zone #{zone_id}.")
        r53_record = r53_record.first
        r53_record[:result] = 0
      else
        Puppet.send(:debug, "More than one record #{name} of type #{type} in zone #{zone_id}. Strictly speaking, this should never happen.")
        r53_record = {:result => 2}
      end

    rescue Aws::Route53::Errors
      Puppet.send(:warn, "Unable to complete Route53 request for getting record #{name} of type #{type} in zone #{zone_id} due to #{e}")
      r53_record = {:result => 3}
    end

    r53_record
  end
end
