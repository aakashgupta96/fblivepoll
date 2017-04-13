Redis.current = Redis.new(:host => "35.154.196.122", :port => 6379, :thread_safe => true, auth: "rasenshuriken")
Resque.redis = Redis.current