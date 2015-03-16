require 'securerandom'

module Puppet::Parser::Functions
  newfunction(:update_internal_dns) do |args|
    r53_zone, base, hostname = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    r53 = Aws::Route53::Client.new(region:region)
    begin
      zones = r53.list_hosted_zones_by_name(dns_name: r53_zone).to_hash[:hosted_zones].select{|zone|
          zone[:config][:private_zone] and (
              (zone[:name] == r53_zone) or
              (zone[:name] == "#{r53_zone}."))
      }

      if (zones.count == 0)
        Puppet.send(:notice, "No zones with the DNS name of #{r53_zone}, taking no action.")
      elsif zones.count == 1
        zone_id = zones[0][:id]
        Puppet.send(:notice, "Located Route53 Zone with DNS name of #{r53_zone} and id #{zone_id}.")
      else
        Puppet.send(:notice, "More than one zone with the DNS name of #{r53_zone}, taking no action.")
      end

      if zone_id
        begin
          zone = r53.get_hosted_zone(id: zone_id).to_hash
          while not first_record
            records = r53.list_resource_record_sets(hosted_zone_id: zone_id, start_record_name: first_record)
            matches = records[:resource_record_sets].select{|record| record[:name] =~ /^#{base}/}
            if matches.count > 0
                first_record = matches.first[:name]
            elsif not matches.is_truncated?
                break
            end
          end

          if first_record
              temp_records = r53.list_resource_record_sets(hosted_zone_id: zone_id, start_record_name: first_record).to_hash
              while temp_records[:max_items] == temp_records[:resource_record_sets].select{|record| record[:name] =~ /^#{base}/}.count
                full_list += temp_records[:resource_record_sets].select{|record| record[:name] =~ /^#{base}/}
                temp_records = r53.list_resource_record_sets(hosted_zone_id: zone_id, start_record_name: first_record).to_hash
              end
              full_list.each{|record|

          zone[:vp_cs].each{|vpc| 

                  



              

          }
          
          if zone[:vp_cs].select{|vpc| vpc[:vpc_id] == vpc_id}.count == 0
            Puppet.send(:notice, "Route53 zone #{r53_zone} not currently associated with vpc #{vpc_id}, associating.")
            r53.associate_vpc_with_hosted_zone(hosted_zone_id: zone_id, vpc: {vpc_region: region, vpc_id: vpc_id}, comment: "Associated by puppet-aws on #{Time.now}")
          else
            Puppet.send(:notice, "Route53 zone #{r53_zone} is already associated with vpc #{vpc_id}.")
          end
        rescue Aws::Route53::Errors::ServiceError
          Puppet.send(:warn, e)
        end
      end
    end
  end
end
