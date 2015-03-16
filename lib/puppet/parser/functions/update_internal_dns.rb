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
          changes = {}
          changes[:hosted_zone_id] = zone_id
          changes[:change_batch] = {}
          changes[:change_batch][:comment] = "Updated by puppet-aws on #{Facter.value(aws::bootstrap::fqdn)} at #{Time.now()}."
          changes[:change_batch][:changes] = []

          record = r53.list_resource_record_sets(hosted_zone_id: zone_id, start_record_name: base, start_record_type: "CNAME")[:resource_record_sets].select{|rec| 
              (rec[:name] =~ /#{base}\.#{r53_zone}/) and 
              (rec[:type] == "CNAME" ) 
          }

          if record.count == 0
              Puppet.send(:notice, "No cname exists for #{base}.#{r53_zone}, creating it.")
              change = changes 
              change[:change_batch][:changes][0][:action] = "CREATE"
              change[:change_batch][:changes][0][:resource_record_set] = {}
              change[:change_batch][:changes][0][:resource_record_set][:name] = "#{base}.#{r53_zone}"
              change[:change_batch][:changes][0][:resource_record_set][:type] = "CNAME"
              change[:change_batch][:changes][0][:resource_record_set][:resource_records] = []
              change[:change_batch][:changes][0][:resource_record_set][:resource_records].push({value: Facter.value(aws::bootstrap::fqdn)})
              resp = r53.change_resource_record_sets(change)
              Puppet.send(:debug, "Response: #{resp[:change_info].to_hash.to_s}")
              sleep(5)
              record = r53.list_resource_record_sets(hosted_zone_id: zone_id, start_record_name: base, start_record_type: "CNAME")[:resource_record_sets].select{|rec| 
                  (rec[:name] =~ /#{base}\.#{r53_zone}/) and 
                  (rec[:type] == "CNAME" ) 
              }
          end

          ec2_conns = {}
          record[:resource_records].each{|hostname|
              # get r53 A and TXT records for that hostname

              records = r53.list_resource_record_sets(hosted_zone_id: zone_id, start_record_name: hostname[:value])[:resource_record_sets].select{|rec| rec[:name] == hostname[:value]}
              txt_rec = records.select{|rec| rec[:type] == "TXT"}[:resource_records]
              a_rec   = records.select{|rec| rec[:type] == "A"}[:resource_records]

              # split TXT record, check vpc and verify that that instance id is still running.

              if txt_rec.count == 1
                vpc_id      = txt_rec.split(',')[0]
                instance_id = txt_rec.split(',')[1]
                interface_id = txt_rec.split(',')[2]
              else
                Puppet.send(:warn, "TXT record for #{hostname[:value]} isn't correct.")
              end

              if zone[:vp_cs].select{|vpc| vpc[:vpc_id] == vpc_id} 
                # if instance is still running, do nothing.
                region = zone[:vp_cs].select{|vpc| vpc[:vpc_id] == vpc_id}[0][:region].to_sym
                if not ec2_conns[region]
                  ec2_conns[region] = Aws::EC2::Client.new(region: region.to_s)
                end
                begin 
                    instance = Aws::EC2::Instance.new(id: instance_id, client: ec2_conns[region])
                    if instance.state[:name] == "running"
                        if a_rec == instance.network_interfaces.last.private_ip_address
                            Puppet.send(:debug, "#{instance.network_interfaces.last.network_interface_id} on #{instance_id} still valid for #{hostname[:value]}.")
                        else
                            Puppet.send(:debug, "#{instance.network_interfaces.last.network_interface_id} on #{instance_id} no longer valid for #{hostname[:value]}, deleting.")


                rescue Aws::EC2::Errors::InvalidInstanceIDNotFound

              else
                # if instance doesn't exist, delete TXT and A records, remove record set from base tag cname.




              

          }

          # Finally, add A, TXT and record set for the new instance (self)
          
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
