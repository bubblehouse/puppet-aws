module Puppet::Parser::Functions
  newfunction(:ec2_detect_volume, :type => :rvalue) do |args|
    Puppet.send(:notice, args)
    tag, az = *args
    region = Facter.value(az).chop
    ec2 = Aws::EC2::Client.new(region:region)
    begin
      resp = ec2.describe_volumes(
        volume_ids: ["String", '...'],
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
      resp[:volumes][0][:volume_id]
    rescue Aws::EC2::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Compute Cloud
      function_notice(e)
    end
  end
end