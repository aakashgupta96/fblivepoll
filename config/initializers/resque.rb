require 'resque-scheduler'
require 'resque/scheduler/server'
require 'resque/scheduler/tasks'

Resque::Server.use(Rack::Auth::Basic) do |user,password|
	password == ENV["AUTH"]
end
