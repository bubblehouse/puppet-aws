require 'json'

module Puppet::Parser::Functions
  newfunction(:ec2_detect_volume, :type => :rvalue) do |args|
    tag, az = *args
    region = az.chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      Puppet.send(:debug, "Searching #{az} for volume tagged #{tag}")
      resp = ec2.describe_volumes(
        filters: [{
          name: "availability-zone",
          values: [az],
        }, {
          name: "tag-key",
          values: ["Name"],
        }, {
          name: "tag-value",
          values: [tag],
        }]
      )
      if(resp[:volumes].count > 0)
        Puppet.send(:debug, "Found #{resp[:volumes][0][:volume_id]}")
        resp[:volumes][0][:volume_id]
      else
        Puppet.send(:debug, "No volume found for #{tag} in #{az}")
        nil
      end
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      Puppet.send(:err, "Error trying to detect volume: #{e}")
    end
  end
end