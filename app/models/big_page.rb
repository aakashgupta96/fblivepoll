class BigPage < ActiveRecord::Base
	
	paginates_per Constant::BIGPAGES_PER_PAGE

	def self.update_pages_info
		all.each do |bp|
			query = "https://graph.facebook.com/v2.8/#{bp.page_id}?fields=name,picture.type(large){url},fan_count&access_token=#{ENV['FB_ACCESS_TOKEN']}"
			response = HTTParty.get(query)
			if response.ok?
				bp.update(name: response.parsed_response["name"], image_url: response.parsed_response["picture"]["data"]["url"], fan_count: response.parsed_response["fan_count"])
			else
				puts response.parsed_response["error"]["message"],response.code,bp.page_id 
			end	
		end
	end

	def self.get_big_pages_ids(follower_count=100000,batch_size=49)
		pages_array = Array.new
		big_pages = Set.new
		erroneous_pages = Array.new
		LiveStream.all.pluck(:page_id).to_set.each do |page_id|
			next if page_id.nil?
			if pages_array.size <= batch_size	
				pages_array << page_id
			else
				query = "https://graph.facebook.com/v2.8/?ids=#{pages_array.join(',')}&fields=fan_count&access_token=#{ENV['FB_ACCESS_TOKEN']}"
				begin
					response = HTTParty.get(query)
					if response.ok?
						response.parsed_response.each do |id,value|
							if value["fan_count"].to_i > follower_count
								big_pages << id
							end
						end
					else
						erroneous_pages += pages_array
						#puts response.code,response.parsed_response["error"]["message"],pages_array.join(",")
					end
				rescue Exception => e
					puts e.class, e.message
				end
				pages_array.clear
			end
		end
		#Work for Last batch in array
		query = "https://graph.facebook.com/v2.8/?ids=#{pages_array.join(',')}&fields=fan_count&access_token=#{ENV['FB_ACCESS_TOKEN']}"
		pages_array.clear
		begin
			response = HTTParty.get(query)
			if response.ok?
				response.parsed_response.each do |id,value|
					if value["fan_count"].to_i > follower_count
						big_pages << id
					end
				end
			end
		rescue Exception => e
			puts e.class, e.message
		end

		#Retrying individually for each page where error occured
		erroneous_pages.each do |page_id|
			query = "https://graph.facebook.com/v2.8/?ids=#{page_id}&fields=fan_count&access_token=#{ENV['FB_ACCESS_TOKEN']}"
			begin
				response = HTTParty.get(query)
				if response.ok?
					response.parsed_response.each do |id,value|
						if value["fan_count"].to_i > follower_count
							big_pages << id
						end
					end
				else
					puts response.code,response.parsed_response["error"]["message"],page_id
				end
			rescue Exception => e
					puts e.class, e.message
			end
		end
		return big_pages
	end

	def self.set_initial_data
		f = File.read(Rails.root.join("public").join("page_ids.txt")).split("\n")
		f.each do |page_id|
			query = "https://graph.facebook.com/v2.8/#{page_id}?fields=name,picture.type(large){url},fan_count&access_token=#{ENV['FB_ACCESS_TOKEN']}"
			response = HTTParty.get(query)
			if response.ok?
				BigPage.create(page_id: page_id,name: response.parsed_response["name"], image_url: response.parsed_response["picture"]["data"]["url"], fan_count: response.parsed_response["fan_count"])
			else
				puts response.parsed_response["error"]["message"],response.code,page_id 
			end	
		end
	end

end
