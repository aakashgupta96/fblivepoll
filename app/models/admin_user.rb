class AdminUser < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable

  def self.get_big_pages_ids(follower_count=100000,batch_size=49)
		pages_array = Array.new
		big_pages = Set.new
		Post.all.pluck(:page_id).to_set.each do |page_id|
			if pages_array.size < 49	
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
						puts response.code,response.parsed_response["error"]["message"],pages_array.join(",")
					end
				rescue Exception => e
					puts e.class, e.message
				end
				pages_array.clear
			end
		end
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
		return big_pages
	end

end
