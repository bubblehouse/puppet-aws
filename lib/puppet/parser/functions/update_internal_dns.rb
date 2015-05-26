module Puppet::Parser::Functions
  newfunction(:update_internal_dns) do |args|
    r53_zone, base, hostname = *args
    prefix = "dns_metadata"
    region = Facter.value(:aws_region)
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

        txt_record  = function_r53_get_record([zone.id, "#{base}.#{prefix}", "TXT"])
        a_record    = function_r53_get_record([zone.id, hostname, "A"])
        base_record = function_r53_get_record([zone.id, base, "A"])

        Puppet.send(:debug, "r53_get_record returned TXT  : #{txt_record}")
        Puppet.send(:debug, "r53_get_record returned A    :#{a_record}")
        Puppet.send(:debug, "r53_get_record returned Base : #{base_record}")

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
                  type: "A",
                  ttl: 600,
                  resource_records: [{value: "#{Facter.value('ipaddress')}"}]
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
            if a_record[:record][:resource_records].first[:value] != Facter.value('ipaddress')
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

          # Start compiling the new TXT record and base
          new_txt = {
            action: "CREATE",
            resource_record_set: {
              name: "#{base}.#{prefix}.#{zone.name}",
              type: "TXT",
              ttl: 600,
              resource_records: []
            }
          }

          new_base = {
            action: "CREATE",
            resource_record_set: {
              name: "#{base}.#{zone.name}",
              type: "A",
              ttl: 600,
              resource_records: []
            }
          }

          # Loop through original TXT record and check if they all still exist.
          txt_record[:record][:resource_records].each{|record|
            region, instance_id, cname = *record[:value].slice(1..-2).split(',')
            Puppet.send(:debug, "Verifying existing of #{instance_id} - #{cname} in #{region}.")
            remove = false

            # If it still exists, keep it in the new TXT and CNAME records.
            instance = Aws::EC2::Instance.new(id: instance_id, region: region)
            if instance.exists?
              if instance.state.name == "running"
                Puppet.send(:debug, "#{instance_id} - #{cname} in #{region} still exists.")
                new_txt[:resource_record_set][:resource_records].push(record)
                if hostname != base
                  new_base[:resource_record_set][:resource_records].push({value: instance.private_ip_address })
                end
              else
                remove = true
              end
            # If it doesn't, delete the associated A record and leave it out of the new TXT and base.
            else
              remove = true
            end
            if remove == true
              Puppet.send(:debug, "#{instance_id} - #{cname} in #{region} doesn't exist or isn't running.")
              check_for_a_record = function_r53_get_record([zone.id, cname, "A"])
              if check_for_a_record[:result] == 0
                change_batch[:change_batch][:changes].push({
                  action: "DELETE",
                  resource_record_set: check_for_a_record[:record]
                })
              end
            end
          }

          new_txt[:resource_record_set][:resource_records].push({value: "\"#{region},#{Facter.value('ec2_instance_id')},#{Facter.value('hostname')}\""})

          # If there are changes, delete the old TXT record and create the new one.
          if new_txt[:resource_record_set].sort != txt_record[:record][:resource_records][:resource_record_set].sort
            change_batch[:change_batch][:changes].push({
              action: "DELETE",
              resource_record_set: txt_record[:record]
            })

            change_batch[:change_batch][:changes].push(new_txt)
          end

          # If there are changes, delete the old base record and create the new one.
          if hostname != base
            if new_base[:resource_record_set] != base_record[:record]
              change_batch[:change_batch][:changes].push({
                action: "DELETE",
                resource_record_set: base_record[:record]
              })

              change_batch[:change_batch][:changes].push(new_base)
            end
          end
        end
        Puppet.send(:debug, "Compiled change request: #{change_batch}")
        if change_batch[:change_batch][:changes].count > 0
          r53.change_resource_record_sets(change_batch)
          Puppet.send(:info, "Updating DNS...")
        else
          Puppet.send(:debug, "No changes to DNS, no update sent")
        end
      end
    rescue => e
      Puppet.send(:warn, e)
    end
  end
end
