CarrierWave.configure do |config|

	if Rails.env.development? || Rails.env.test?
		config.storage = :file
	else
		config.fog_provider = 'fog/aws'
	  config.fog_credentials = {
	      :provider               => 'AWS',
	      :aws_access_key_id      => ENV['AWS_ACCESS_KEY'],
	      :aws_secret_access_key  => ENV['AWS_SECRET_KEY'],
	      :region                 => 'ap-south-1' # Change this for different AWS region. Default is 'us-east-1'
	  }
	  config.fog_directory  = "shurikenlive"
	end

end