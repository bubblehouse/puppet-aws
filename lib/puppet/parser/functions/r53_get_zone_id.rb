#
# Get the route 53 zone id
# Returns 0 if zone doesn't exist.
# Returns 2 if more than one zone of that name exists.
# Returns the zone_id (/hostedzone/1234567890ABCD) if a single zone exists.
#

module Puppet::Parser::Functions
  newfunction(:r53_get_zone_id, :type => :rvalue) do |args|
    r53_zone = args[0]
    region = Facter.value(:ec2_placement_availability_zone).chop
    r53 = Aws::Route53::Client.new(region:region)
    begin
      zones = r53.list_hosted_zones_by_name(dns_name: r53_zone).to_hash[:hosted_zones].select{|zone|
          zone[:config][:private_zone] and (
              (zone[:name] == r53_zone) or
              (zone[:name] == "#{r53_zone}."))
      }

      if (zones.count == 0)
        Puppet.send(:debug, "No zones exist with the DNS name of #{r53_zone}.")
        zone_id = 0
      elsif zones.count == 1
        zone_id = zones[0][:id]
        Puppet.send(:debug, "Located Route53 Zone with DNS name of #{r53_zone} and id #{zone_id}.")
      else
        Puppet.send(:debug, "More than one zone with the DNS name of #{r53_zone}, taking no action.")
        zone_id = 2
      end

      zone_id
    end
  end
end
