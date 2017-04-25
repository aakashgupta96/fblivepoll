if Rails.env.production?
	Redis.current = Redis.new(:host => ENV['HOST'], :port => ENV['POST'], :thread_safe => true, auth: ENV['AUTH'])
	Redis.current.auht(ENV['AUTH'])
	Resque.redis = Redis.current
end