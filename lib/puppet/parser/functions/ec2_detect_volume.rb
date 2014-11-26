require 'json'

module Puppet::Parser::Functions
  newfunction(:ec2_detect_volume, :type => :rvalue) do |args|
    tag, az = *args
    region = az.chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
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
      Puppet.send(:notice, resp.data.to_json)
      if(resp[:volumes].count > 0)
        resp[:volumes][0][:volume_id]
      else
        nil
      end
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      Puppet.send(:err, e)
    end
  end
end