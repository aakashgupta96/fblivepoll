class FbPage < ActiveRecord::Base
	
	enum status: [:small, :removed, :big]
	validates :page_id, uniqueness: true, presence: true
	paginates_per Constant::BIGPAGES_PER_PAGE
	
	def self.update_information(follower_count=100000,batch_size=49)
		#Adding new pages to table
		new_page_ids = (LiveStream.pluck(:page_id).compact.to_set - all.pluck(:page_id).to_set)
		new_page_ids.each do |page_id|
			create(page_id: page_id)
		end

		current_batch = Array.new
		erroneous_pages = Array.new
		complete_batch = FbPage.big.pluck(:page_id) + FbPage.small.pluck(:page_id)
		complete_batch.each do |page_id|
			if current_batch.size <= batch_size	
				current_batch << page_id
			else
				query = "https://graph.facebook.com/v2.8/?ids=#{current_batch.join(',')}&fields=name,picture.type(large){url},fan_count&access_token=#{ENV['FB_ACCESS_TOKEN']}"
				begin
					response = HTTParty.get(query)
					if response.ok?
						response.parsed_response.each do |page_id,value|
							page = FbPage.find_by_page_id(page_id)
							page.update(name: value["name"], image_url: value["picture"]["data"]["url"], fan_count: value["fan_count"])
							page.big! if (value["fan_count"].to_i > follower_count)
						end
					else
						erroneous_pages += current_batch
						#puts response.code,response.parsed_response["error"]["message"],current_batch.join(",")
					end
				rescue Exception => e
					puts e.class, e.message
				end
				current_batch.clear
			end
		end
		
		#Work for Last batch in array
		query = "https://graph.facebook.com/v2.8/?ids=#{current_batch.join(',')}&fields=name,picture.type(large){url},fan_count&access_token=#{ENV['FB_ACCESS_TOKEN']}"
		current_batch.clear
		begin
			response = HTTParty.get(query)
			if response.ok?
				response.parsed_response.each do |page_id,value|
					page = FbPage.find_by_page_id(page_id)
					page.update(name: value["name"], image_url: value["picture"]["data"]["url"], fan_count: value["fan_count"])
					page.big! if (value["fan_count"].to_i > follower_count)
				end
			else
				erroneous_pages += current_batch
			end
		rescue Exception => e
			puts e.class, e.message
		end

		#Retrying individually for each page where error occured
		erroneous_pages.each do |page_id|
			query = "https://graph.facebook.com/v2.8/?ids=#{page_id}&fields=name,picture.type(large){url},fan_count&access_token=#{ENV['FB_ACCESS_TOKEN']}"
			begin
				response = HTTParty.get(query)
				if response.ok?
					response.parsed_response.each do |id,value|
						page = FbPage.find_by_page_id(page_id)
						page.update(name: value["name"], image_url: value["picture"]["data"]["url"], fan_count: value["fan_count"])
						page.big! if (value["fan_count"].to_i > follower_count)
					end
				else
					puts response.code,response.parsed_response["error"]["message"],page_id
					FbPage.find_by_page_id(page_id).removed!
				end
			rescue Exception => e
				FbPage.find_by_page_id(page_id).removed!
				puts e.class, e.message
			end
		end
	end
end
