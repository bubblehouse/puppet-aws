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

        change_batch = {
          :hosted_zone_id => zone.id,
          :change_batch => {
            :comment => "Updated by puppet-aws on #{hostname} at #{Time.now()}.",
            :changes => []
          }
        }

        change_template = {
          :action => "CREATE",
          :resource_record_set => {
            :ttl => 600,
            :resource_records => []
          }
        }

        txt_record = function_r53_get_record([zone.id, base, "TXT"])
        Puppet.send(:debug, "r53_get_record returned #{txt_record}")
        Puppet.send(:debug, "r53_get_record returned #{txt_record.class}")

        if txt_record.class == Fixnum
          if txt_record == 0
            Puppet.send(:notice, "No TXT exists for #{base}.#{r53_zone}, creating it.")
            change = Marshal.load(Marshal.dump(change_template))
            change[:resource_record_set][:name] = "#{base}.#{zone.name}"
            change[:resource_record_set][:type] = "TXT"
            change[:resource_record_set][:resource_records].push({value: "\"#{region},#{Facter.value('ec2_instance_id')},#{Facter.value('hostname')}\""})
            change_batch[:change_batch][:changes].push(change)

            change = Marshal.load(Marshal.dump(change_template))
            change[:resource_record_set][:name] = "#{base}.#{zone.name}"
            change[:resource_record_set][:type] = "A"
            change[:resource_record_set][:resource_records].push({value: "#{Facter.value('ipaddress')}" })
            change_batch[:change_batch][:changes].push(change)
          end
        elsif txt_record.class == Array
          Puppet.send(:debug, "Retrieved TXT record: #{txt_record.first.to_s}")

          # Delete the old TXT record
          delete_original_txt = txt_record.first.to_hash
          delete_original_txt[:action] = "DELETE"
          change_batch[:change_batch][:changes].push(delete_original_txt)

          # Create the A record
          change = change_template
          change[:resource_record_set][:name] = "#{base}.#{zone.name}"
          change[:resource_record_set][:type] = "A"
          change[:resource_record_set][:resource_records].push({value: "#{Facter.value('ipaddress')}" })
          change_batch[:change_batch][:changes].push(change)

          # Start compiling the new TXT record
          new_txt = change_template
          new_txt[:name] = "#{base}.#{zone.name}"
          new_txt[:type] = "TXT"
          new_txt[:resource_record_set][:resource_records].push({value: "\"#{region},#{Facter.value('ec2_instance_id')}\""})

          # Loop through original TXT record and check if they all still exist.
          txt_record.resource_records.each{|record|
            region, instance_id, hostname = *record.split(',')

            # If it still exists, keep it in the new TXT record.
            if Aws::EC2::Instance.new(id: instance_id, region: region).exists?
              change[:resource_record_set][:resource_records].push({value: "\"#{region},#{instance_id}')}\""})

            # If it doesn't, delete the associated A record and leave it out of the new TXT
            else
              check_for_a_record = function_r53_get_record([zone.id, hostname, "A"])
              if check_for_a_record.class == Array
                terminated_instance = check_for_a_record.first
                terminated_instance[:action] = "DELETE"
                change_batch[:change_batch][:changes].push(terminated_instance)
              end
            end
          }

          change_batch[:change_batch][:changes].push(change)

        end
        Puppet.send(:debug, "Compiled change request: #{change_batch}")
        r53.change_resource_record_sets(change_batch)
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
