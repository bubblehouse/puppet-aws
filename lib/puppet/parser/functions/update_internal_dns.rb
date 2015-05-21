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

        change_template = Marshal.dump({
          :action => "CREATE",
          :resource_record_set => {
            :ttl => 600,
            :resource_records => []
          }
        })

        txt_record   = function_r53_get_record([zone.id, base, "TXT"])
        a_record     = function_r53_get_record([zone.id, hostname, "A"])
        cname_record = function_r53_get_record([zone.id, base, "CNAME"])

        Puppet.send(:debug, "r53_get_record returned TXT  : #{txt_record}")
        Puppet.send(:debug, "r53_get_record returned A    :#{a_record}")
        Puppet.send(:debug, "r53_get_record returned CNAME: #{cname_record}")

        if txt_record[:result] == 1
            Puppet.send(:notice, "No TXT exists for #{base}.#{r53_zone}, creating it.")
            change = Marshal.load(change_template)
            change[:resource_record_set][:name] = "#{base}.#{zone.name}"
            change[:resource_record_set][:type] = "TXT"
            change[:resource_record_set][:resource_records].push({value: "\"#{region},#{Facter.value('ec2_instance_id')},#{Facter.value('hostname')}\""})
            change_batch[:change_batch][:changes].push(change)

            change = Marshal.load(change_template)
            change[:resource_record_set][:name] = "#{hostname}.#{zone.name}"
            change[:resource_record_set][:type] = "A"
            change[:resource_record_set][:resource_records].push({value: "#{Facter.value('ipaddress')}" })
            change_batch[:change_batch][:changes].push(change)

            if hostname != base
              change = Marshal.load(change_template)
              change[:resource_record_set][:name] = "#{base}.#{zone.name}"
              change[:resource_record_set][:type] = "CNAME"
              change[:resource_record_set][:resource_records].push({value: "#{hostname}.#{zone.name}" })
              change_batch[:change_batch][:changes].push(change)
            end

        elsif txt_record[:result] == 0
          Puppet.send(:debug, "Retrieved TXT record: #{txt_record.to_s}")

          # Delete the old TXT record
          delete_original_txt = Marshal.load(change_template)
          delete_original_txt[:action] = "DELETE"
          delete_original_txt[:resource_record_set] = Marshal.load(Marshal.dump(txt_record[:record]))
          change_batch[:change_batch][:changes].push(delete_original_txt)

          # Check for the current A record
          if a_record[:result] == 1
            # Create the A record
            change = Marshal.load(change_template)
            change[:resource_record_set][:name] = "#{hostname}.#{zone.name}"
            change[:resource_record_set][:type] = "A"
            change[:resource_record_set][:resource_records].push({value: "#{Facter.value('ipaddress')}" })
            change_batch[:change_batch][:changes].push(change)
          elsif a_record[:result] == 0
            # Is the current A record still correct?
            if a_record[:resource_record_set][:resource_records].first.value != Facter.value('ipaddress')
              # If not, delete it and create a new one.
              delete_original_a = Marshal.load(Marshal.dump(a_record[:record]))
              delete_original_a[:action] = "DELETE"
              change_batch[:change_batch][:changes].push(delete_original_a)

              new_a = a_record.to_hash
              new_a[:resource_record_set][:resource_records] = [{value: "#{Facter.value('ipaddress')}" }]
              new_a[:action] = "CREATE"
              change_batch[:change_batch][:changes].push(new_a)
            end
          end

          # Start compiling the new TXT record
          new_txt = Marshal.load(change_template)
          new_txt[:name] = "#{base}.#{zone.name}"
          new_txt[:type] = "TXT"
          new_txt[:resource_record_set][:resource_records].push({value: "\"#{region},#{Facter.value('ec2_instance_id')}\""})

          # Loop through original TXT record and check if they all still exist.
          txt_record[:record][:resource_records].each{|record|
            Puppet.send(:debug, "Processing record: #{record}")
            region, instance_id, cname = *record[:value].slice(1..-2).split(',')
            Puppet.send(:debug, "Verifying existing of #{instance_id} - #{cname} in #{region}.")

            # If it still exists, keep it in the new TXT record.
            if Aws::EC2::Instance.new(id: instance_id, region: region).exists?
              change[:resource_record_set][:resource_records].push({value: "\"#{region},#{instance_id}')}\""})

            # If it doesn't, delete the associated A and CNAME records and leave it out of the new TXT
            else
              check_for_a_record = function_r53_get_record([zone.id, cname, "A"])
              if check_for_a_record[:result] == 0
                terminated_instance = check_for_a_record[:record]
                terminated_instance[:action] = "DELETE"
                change_batch[:change_batch][:changes].push(terminated_instance)
              end

              check_for_cname_record = function_r53_get_record([zone.id, cname, "CNAME"])
              if check_for_cname_record[:result] == 0
                terminated_instance = Marshal.load(Marshal.dump(check_for_cname_record[:record]))
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
