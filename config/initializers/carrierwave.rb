CarrierWave.configure do |config|

	if Rails.env.development? || Rails.env.test?
		config.storage = :file
		ENV["prefix"] = "../../.."
	else
		config.fog_credentials = {
	      :provider               => 'AWS',
	      :aws_access_key_id      => ENV['AWS_ACCESS_KEY'],
	      :aws_secret_access_key  => ENV['AWS_SECRET_KEY'],
	      :region                 => 'ams3', # Change this for different AWS region. Default is 'us-east-1'
	      :endpoint               => 'https://ams3.digitaloceanspaces.com'
	  }
	  config.storage = :fog
	  config.fog_directory  = "swarnimtouch"
	  config.fog_attributes = { :multipart_chunk_size => 104857600 }
		ENV["prefix"] = ""
	end

end