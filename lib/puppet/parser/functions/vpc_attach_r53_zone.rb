require 'securerandom'

module Puppet::Parser::Functions
  newfunction(:vpc_attach_r53_zone) do |args|
    vpc_id, r53_zone = *args
    region = Facter.value(:ec2_placement_availability_zone).chop
    r53 = Aws::Route53::Client.new(region:region)
    begin
      zones = r53.list_hosted_zones_by_name(dns_name: r53_zone)
      if (zones[:hosted_zones].count == 0)
        Puppet.send(:debug, "No zones with the DNS name of #{r53_zone}, creating one.")
        zone = {}
        zone[:name] = r53_zone
        zone[:vpc] = {vpc_region: region, vpc_id: vpc_id}
        zone[:caller_reference] = SecureRandom.uuid
        zone[:hosted_zone_config] = {comment: "created by puppet-aws on #{Time.now}.", private_zone: true}
        resp = e53.create_hosted_zone(zone)
        Puppet.send(:debug, resp[:change_info].to_s)
        sleep(10)
        zones = r53.list_hosted_zones_by_name(dns_name: r53_zone)
        if zones[:hosted_zones].count != 1
          Puppet.send(:warn, "Zone still not created, moving on.")
        else
          zone_id = zones[:hosted_zones][0][:id]
        end
      elsif zones[:hosted_zones].count == 1
        zone_id = zones[:hosted_zones][0][:id]
        Puppet.send(:debug, "Located Route53 Zone with DNS name of #{r53_zone} and id #{zone_id}.")
      else
        Puppet.send(:debug, "More than one zone with the DNS name of #{r53_zone}, taking no action.")
      end

      if zone_id
        begin
          zone = r53.get_hosted_zone(id: zone_id)[:hosted_zones]
          if zone[:vp_cs].select{|vpc| vpc[:vpc_id] == vpc_id}.count == 0
            Puppet.send(:debug, "Route53 zone #{r53_zone} not currently associated with vpc #{vpc_id}, associating.")
            r53.associate_vpc_with_hosted_zone(hosted_zone_id: zone_id, vpc: {vpc_region: region, vpc_id: vpc_id}, comment: "Associated by puppet-aws on #{Time.now}")
          end
        rescue Aws::Route53::Errors::ServiceError
          Puppet.send(:warn, e)
        end
      end
    end
  end
end
