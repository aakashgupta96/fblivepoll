module Deployment
	
	require 'net/ssh'
	require 'droplet_kit'
	
	aakash = "131e183d206e11ceafa8fc1ab2b81f56b31e701ddb4254b0388e2475b07df367"
	akhil = "cae6ae9fc98b3e1ad2a4b008c61e64695902fc82d6bb951404d44180f19badde"

	def add_ip_to_pg(ip_address="123.456.789.000",hostname="db.shurikenlive.com",user="ubuntu")
		#Assuming public keys of local machine are authorized fby the host
		ssh = Net::SSH.start(hostname,user)
		#trying to add a test line to text file
		result = "host all all #{ip_address}/32 trust"
		file_dir = "/etc/postgresql/9.3/main/pg_hba.conf"
		puts "Adding IP to pg_hba.conf"
		
		output = ssh.exec!("sudo cp #{file_dir} #{file_dir}.bak")
		puts output

		output = ssh.exec!("echo '#{result}' | sudo tee -a /etc/postgresql/9.3/main/pg_hba.conf")
		puts output

		output = ssh.exec!("sudo service postgresql reload")
		puts output

		ssh.close
	end

	def remove_ip_from_pg(ip_address="123.456.789.000",hostname="db.shurikenlive.com",user="ubuntu")
		ssh = Net::SSH.start(hostname,user)
		#trying to add a test line to text file
		result = "host all all #{ip_address}/32 trust"
		file_dir = "/etc/postgresql/9.3/main/pg_hba.conf"
		puts "Removing IP from pg_hba.conf"

		output = ssh.exec!("sudo grep -v '#{ip_address}' #{file_dir} | sudo tee -a ~/tmp.conf")
		puts output

		output = ssh.exec!("sudo mv ~/tmp.conf #{file_dir}")
		puts output
		
		output = ssh.exec!("sudo service postgresql reload")
		puts output
		
		ssh.close
	end

	def take_snapshot(access_token,default_timeout = 600)
		client = DropletKit::Client.new(access_token: access_token)
		d1 = client.droplets.all.first
		current_size = d1.snapshot_ids.count
		action = client.droplet_actions.snapshot(droplet_id: d1.id, name: "ShurikenLive-Worker")
		puts "Snapshot Action Started with action_id = #{action.id}"
		completed = false
		t = Time.now
		until completed
			sleep 5
			elapsed_time = (Time.now - t).to_i
			raise "Timout Error" if elapsed_time > default_timeout
			puts "Waiting for Action To Complete"
			puts "Time elapsed = #{elapsed_time} seconds"
			completed = true if client.actions.find(id: action.id).status == "completed"
		end
		puts "Task completed"
		return client.snapshots.find(id: client.droplets.all.first.snapshot_ids.last)
	end

	def create_droplet_from(access_token,image_id,name,default_timeout = 600)
		client = DropletKit::Client.new(access_token: access_token)
		key = client.ssh_keys.all.first.fingerprint
		new_droplet = DropletKit::Droplet.new(name: name, region: 'ams2', size: "s-1vcpu-1gb", image: image_id.to_i, ssh_keys: [key])
		d = client.droplets.create(new_droplet)
		puts "New Droplet ID = #{d.id}"
		completed = false
		t = Time.now
		until completed
			sleep 5
			elapsed_time = (Time.now - t).to_i
			raise "Timout Error" if elapsed_time > default_timeout
			puts "Waiting for Action To Complete"
			puts "Time elapsed = #{elapsed_time} seconds"
			completed = true if client.droplets.find(id: d.id).status == "active"
		end
		puts "Task completed"
		client.droplet_actions.reboot(droplet_id: d.id)
		return client.droplets.find(id: d.id)
	end

	def destroy_droplet(access_token,droplet_id)
		client = DropletKit::Client.new(access_token: access_token)
		droplet = client.droplets.find(id: droplet_id)
		client.droplet_actions.shutdown(droplet_id: droplet_id)	
		client.droplets.delete(id: droplet_id)
		return droplet.public_ip
	end

	def deploy_worker(access_token,image_id=31326191,name="ShurikenLive-Test")
		new_droplet = create_droplet_from(access_token,image_id,name)
		add_ip_to_pg(new_droplet.public_ip)
	end

	def undeploy_worker(access_token,droplet_id)
		public_ip = destroy_droplet(access_token,droplet_id)
		remove_ip_from_pg(public_ip)
	end

end
