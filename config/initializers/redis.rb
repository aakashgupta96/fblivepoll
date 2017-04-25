if Rails.env.production?
	Redis.current = Redis.new(:host => ENV['HOST'], :port => ENV['POST'], :thread_safe => true, auth: ENV['AUTH'])
	Redis.current.auth(ENV['AUTH'])
	Resque.redis = Redis.current
end