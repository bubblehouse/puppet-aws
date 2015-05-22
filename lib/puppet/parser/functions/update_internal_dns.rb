module Puppet::Parser::Functions
  newfunction(:update_internal_dns) do |args|
    r53_zone, base, hostname = *args
    prefix = "dns_metadata"
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

        txt_record   = function_r53_get_record([zone.id, "#{base}.#{prefix}", "TXT"])
        a_record     = function_r53_get_record([zone.id, hostname, "A"])
        cname_record = function_r53_get_record([zone.id, base, "CNAME"])

        Puppet.send(:debug, "r53_get_record returned TXT  : #{txt_record}")
        Puppet.send(:debug, "r53_get_record returned A    :#{a_record}")
        Puppet.send(:debug, "r53_get_record returned CNAME: #{cname_record}")

        if txt_record[:result] == 1
            Puppet.send(:notice, "No TXT exists for #{base}.#{r53_zone}, creating it.")
            change_batch[:change_batch][:changes].push({
              action: "CREATE",
              resource_record_set: {
                name: "#{base}.#{prefix}.#{zone.name}",
                type: "TXT",
                ttl: 600,
                resource_records: [{value: "\"#{region},#{Facter.value('ec2_instance_id')},#{Facter.value('hostname')}\""}]
              }
            })

            change_batch[:change_batch][:changes].push({
              action: "CREATE",
              resource_record_set: {
                name: "#{hostname}.#{zone.name}",
                type: "A",
                ttl: 600,
                resource_records: [{value: "#{Facter.value('ipaddress')}"}]
              }
            })

            if hostname != base
              change_batch[:change_batch][:changes].push({
                action: "CREATE",
                resource_record_set: {
                  name: "#{base}.#{zone.name}",
                  type: "CNAME",
                  ttl: 600,
                  resource_records: [{value: "#{hostname}.#{zone.name}" }]
                }
              })
            end

        elsif txt_record[:result] == 0
          Puppet.send(:debug, "Retrieved TXT record: #{txt_record.to_s}")

          # Check for the current A record
          if a_record[:result] == 1
            # Create the A record
            change_batch[:change_batch][:changes].push({
              action: "CREATE",
              resource_record_set: {
                name: "#{hostname}.#{zone.name}",
                ttl: 600,
                type: "A",
                resource_records: [
                  {value: "#{Facter.value('ipaddress')}" }
                ]
              }
            })
          elsif a_record[:result] == 0
            # Is the current A record still correct?
            if a_record[:record][:resource_records].first.value != Facter.value('ipaddress')
              # If not, delete it and create a new one.
              change_batch[:change_batch][:changes].push({
                action: "DELETE",
                resource_record_set: a_record[:record].clone
              })

              new_a = {
                action: "CREATE",
                resource_record_set: a_record[:record].clone
              }

              new_a[:resource_record_set][:resource_records] = [{value: "#{Facter.value('ipaddress')}" }]
              change_batch[:change_batch][:changes].push(new_a)
            end
          end

          # Start compiling the new TXT record and CNAME
          new_txt = {
            action: "CREATE",
            resource_record_set: {
              name: "#{base}.#{prefix}.#{zone.name}",
              type: "TXT",
              ttl: 600,
              resource_records: []
            }
          }

          new_cname = {
            action: "CREATE",
            resource_record_set: {
              name: "#{base}.#{zone.name}",
              type: "cname",
              ttl: 600,
              resource_records: []
            }
          }

          # Loop through original TXT record and check if they all still exist.
          txt_record[:record][:resource_records].each{|record|
            Puppet.send(:debug, "Processing record: #{record}")
            region, instance_id, cname = *record[:value].slice(1..-2).split(',')
            Puppet.send(:debug, "Verifying existing of #{instance_id} - #{cname} in #{region}.")

            # If it still exists, keep it in the new TXT and CNAME records.
            if Aws::EC2::Instance.new(id: instance_id, region: region).exists?
              new_txt[:resource_record_set][:resource_records].push({value: record })
              if hostname != base
                new_cname[:resource_record_set][:resource_records].push({value: cname })
              end

            # If it doesn't, delete the associated A and CNAME records and leave it out of the new TXT
            else
              check_for_a_record = function_r53_get_record([zone.id, cname, "A"])
              if check_for_a_record[:result] == 0
                terminated_instance = {action: "DELETE", resource_record_set: Marshal.load(Marshal.dump(check_for_a_record[:record]))}
                change_batch[:change_batch][:changes].push(terminated_instance)
              end
            end
          }

          # Delete the old TXT record
          delete_original_txt = {action: "DELETE", resource_record_set: Marshal.load(Marshal.dump(txt_record[:record]))}
          change_batch[:change_batch][:changes].push(delete_original_txt)

          change_batch[:change_batch][:changes].push(new_txt)

        end
        Puppet.send(:debug, "Compiled change request: #{change_batch}")
        r53.change_resource_record_sets(change_batch)
      end
    rescue => e
      Puppet.send(:warn, e)
    end
  end
end
