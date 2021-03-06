# set path to application
app_dir = File.expand_path("../..", __FILE__)
shared_dir = "#{app_dir}/shared"
working_directory app_dir


# Set unicorn options
worker_processes 2
preload_app true
timeout 1200

if ENV["RAILS_ENV"] == "production"
	# Set up socket location
	listen "#{shared_dir}/sockets/unicorn.sock", :backlog => 64
	#listen "/var/sockets/unicorn.sock", :backlog => 64
	# Logging
	stderr_path "#{shared_dir}/log/unicorn.stderr.log"
	stdout_path "#{shared_dir}/log/unicorn.stdout.log"

	# Set master PID location
	pid "#{shared_dir}/pids/unicorn.pid"
end

listen(3000, backlog: 64) if ENV['RAILS_ENV'] == 'development'