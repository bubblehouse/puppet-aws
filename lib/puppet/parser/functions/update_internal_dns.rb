require 'securerandom'

module Puppet::Parser::Functions
  newfunction(:update_internal_dns) do |args|
    r53_zone, base, hostname = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    r53 = Aws::Route53::Client.new(region:region)
    begin
      zone_id = function_r53_get_zone_id([r53_zone])

      if (zone_id == 0)
        Puppet.send(:notice, "No zones with the DNS name of #{r53_zone}, taking no action.")
      elsif zone_id == 2
        Puppet.send(:notice, "More than one zone with the DNS name of #{r53_zone}, taking no action.")
        Puppet.send(:debug, "r53_get_zone_id returned #{zone_id}")
        zone_id = nil
      else
        Puppet.send(:notice, "Located Route53 Zone with DNS name of #{r53_zone} and id #{zone_id}.")
        zone = r53.get_hosted_zone(id: zone_id).hosted_zone
        Puppet.send(:debug, "r53_get_hosted_zone returned #{zone}")

        change_batch_template = {}
        change_batch_template[:hosted_zone_id] = zone.id
        change_batch_template[:change_batch] = {}
        change_batch_template[:change_batch][:comment] = "Updated by puppet-aws on #{hostname} at #{Time.now()}."
        change_batch_template[:change_batch][:changes] = []

        txt_record = function_r53_get_record([zone.id, base, "TXT"])
        Puppet.send(:debug, "r53_get_record returned #{txt_record}")
        Puppet.send(:debug, "r53_get_record returned #{txt_record.class}")

        if txt_record.class == Fixnum
          if txt_record == 0
            Puppet.send(:notice, "No TXT exists for #{base}.#{r53_zone}, creating it.")
            create_txt_record = change_batch_template.dup
            create_txt_record[:change_batch][:changes][0] = {}
            create_txt_record[:change_batch][:changes][0][:action] = "UPSERT"
            create_txt_record[:change_batch][:changes][0][:resource_record_set] = {}
            create_txt_record[:change_batch][:changes][0][:resource_record_set][:name] = "#{base}.#{r53_zone}"
            create_txt_record[:change_batch][:changes][0][:resource_record_set][:type] = "TXT"
            create_txt_record[:change_batch][:changes][0][:resource_record_set][:resource_records] = []
            create_txt_record[:change_batch][:changes][0][:resource_record_set][:resource_records].push({value: "#{region},#{Facter.value('ec2_instanceid')}"})
            resp = r53.change_resource_record_sets(create_txt_record)
            Puppet.send(:debug, "Response: #{resp[:change_info].to_hash.to_s}")
            sleep(5)
            txt_record = function_r53_get_record([zone_id, base, "TXT"])
          end
        end

        if txt_record.class == Hash
            Puppet.send(:debug, "Retrieved TXT record: #{txt_record.to_s}")
        end
      end
    rescue => e 
      Puppet.send(:warn, e)
    end
  end
end
#         ec2_conns = {}
#         ip_map = []

#         base_record[:resource_records].each{|hostname|
#             instance_record = r53.list_resource_record_sets(hosted_zone_id: zone_id, start_record_name: hostname[:value])[:resource_record_sets].select{|rec| 
#                 (rec[:name] == hostname[:value]) and 
#                 (rec[:type] == "TXT")
#             }


#             change[:action] = "UPSERT"
#             change[:resource_record_set] = instance_record

#             instance_record[:resource_records].select!{|entry|
#                 hostname = hostname[:value]
#                 vpc_id = entry.split(',')[0]
#                 instance_id = entry.split(',')[1]
#                 interface_id = entry.split(',')[2]
#                 ipaddr = entry.split(',')[3]
#                 region = entry.split(',')[4]
#                 ip_map.push entry
#             }
#         } 

#         ip_map.each{|entry|
#           if not ec2_conns[entry[:region]]
#             ec2_conns[entry[:region]] = Aws::EC2::Client.new(region: entry[:region])
#           end

#           instance = Aws::EC2::Instance.new(id: entry[:instance_id], client: ec2_conns[entry[:region]])
#           begin 
#             # This will trigger an error if the instance doesn't exist anymore.  
#             if instance.state[:name] == "running"
#               change[ 


#               Puppet.send(:warn, "TXT record for #{hostname[:value]} isn't correct.")
#             end

#             if zone[:vp_cs].select{|vpc| vpc[:vpc_id] == vpc_id} 
#               # if instance is still running, do nothing.
#               region = zone[:vp_cs].select{|vpc| vpc[:vpc_id] == vpc_id}[0][:region].to_sym
#               if not ec2_conns[region]
#                 ec2_conns[region] = Aws::EC2::Client.new(region: region.to_s)
#               end
#               begin 
#                   instance = Aws::EC2::Instance.new(id: instance_id, client: ec2_conns[region])
#                   if instance.state[:name] == "running"
#                       if a_rec == instance.network_interfaces.last.private_ip_address
#                           Puppet.send(:debug, "#{instance.network_interfaces.last.network_interface_id} on #{instance_id} still valid for #{hostname[:value]}.")
#                       else
#                           Puppet.send(:debug, "#{instance.network_interfaces.last.network_interface_id} on #{instance_id} no longer valid for #{hostname[:value]}, deleting.")


#               rescue Aws::EC2::Errors::InvalidInstanceIDNotFound

#             else
#               # if instance doesn't exist, delete TXT and A records, remove record set from base tag cname.




#             

#         }

#         # Finally, add A, TXT and record set for the new instance (self)
#         
#         if zone[:vp_cs].select{|vpc| vpc[:vpc_id] == vpc_id}.count == 0
#           Puppet.send(:notice, "Route53 zone #{r53_zone} not currently associated with vpc #{vpc_id}, associating.")
#           r53.associate_vpc_with_hosted_zone(hosted_zone_id: zone_id, vpc: {vpc_region: region, vpc_id: vpc_id}, comment: "Associated by puppet-aws on #{Time.now}")
#         else
#           Puppet.send(:notice, "Route53 zone #{r53_zone} is already associated with vpc #{vpc_id}.")
