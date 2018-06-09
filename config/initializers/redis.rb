if Rails.env.production?
	Redis.current = Redis.new(:host => ENV['HOST'], :port => ENV['POST'], :thread_safe => true, password: ENV['AUTH'])
	Resque.redis = Redis.current
end