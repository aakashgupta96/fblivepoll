class LiveStream < ActiveRecord::Base
	belongs_to :post
	enum status: [:drafted, :published, :scheduled, :stopped_by_user, :request_declined, :deleted_from_fb, :network_error, :unknown, :queued, :live, :schedule_cancelled, :user_session_invalid]

	def user
		post.user
	end

	def template
		post.template
	end

	def live_on_fb?
		query = "https://graph.facebook.com/v2.8/#{video_id}?fields=live_status&access_token=#{user.token}"
		response = HTTParty.get(query)
		return response.ok? && (response.parsed_response["live_status"] == "LIVE")
	end

	def ended_on_fb?
		unless Constant::RTMP_TEMPLATE_IDS.include?(template.id)
			query = "https://graph.facebook.com/v2.8/#{video_id}?fields=live_status&access_token=#{user.token}"
			response = HTTParty.get(query)
			possible_values = ["PROCESSING","VOD", "LIVE_STOPPED"]
			return response.ok? && possible_values.include?(response.parsed_response["live_status"])
		else
			return true
		end
	end

	def start
		if Constant::RTMP_TEMPLATE_IDS.include?(template.id)
			self.update(status: "queued")
		  return true
		else
			begin
				graph = graph_with_page_token
				if user.member?
					caption_suffix = "\n #{post.default_message}"
				else
					caption_suffix = ""
				end

				if post.ambient?
					video = graph.graph_call("#{page_id}/live_videos",{status: "LIVE_NOW", description: "#{post.caption}#{caption_suffix}", title: post.title, stream_type: "AMBIENT"},"post")
				else
					video = graph.graph_call("#{page_id}/live_videos",{status: "LIVE_NOW", description: "#{post.caption}#{caption_suffix}", title: post.title},"post")
				end
				live_id = video["id"]
			  video_id=graph.graph_call("#{video["id"]}?fields=video")["video"]["id"]
				update(key: video["stream_url"], video_id: video_id, live_id: live_id, status: "queued")
			  return true
			rescue Exception => e
				puts e.class,e.message
	      request_declined!
				return false
			end
		end	
	end

	def stop(status="published")
		begin
      self.graph_with_page_token.graph_call("#{live_id}", {end_live_video: "true"},"post") unless Constant::RTMP_TEMPLATE_IDS.include?(template.id)
    rescue Exception => e
    	puts e.class,e.message
    end
    self.update(status: status)
	end

	def page_access_token
		attempts = 0
		begin
			graph = Koala::Facebook::API.new(user.token)
			access_token = graph.get_page_access_token(page_id)
		rescue Exception => e
			attempts += 1
			retry if attempts <= 1
			raise e
		end
	end

	def graph_with_page_token
		attempts = 0
		begin
			graph = Koala::Facebook::API.new(page_access_token) 			
		rescue Exception => e
			attempts += 1
			retry if attempts <= 3
			raise e
		end
	end

	def update_status
		if Constant::RTMP_TEMPLATE_IDS.include?(template.id)
			self.published!
			return
		end
		begin
			query = "https://graph.facebook.com/v2.8/?ids=#{video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{ENV["FB_ACCESS_TOKEN"]}"
			status = HTTParty.get(query)
			if status.parsed_response["#{video_id}"].nil?
				self.deleted_from_fb!
			else
				self.published!
			end
		rescue Exception => e
			puts e.class,e.message
		end
	end

	def self.update_statuses	
		begin
			stopped_by_user.each do |ls|
				ls.update_status
			end
			unknown.each do |ls|
				if Constant::RTMP_TEMPLATE_IDS.include?(ls.template.id)
					ls.published!
					next
				end
				query = "https://graph.facebook.com/v2.8/?ids=#{ls.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{ENV["FB_ACCESS_TOKEN"]}"
				status = HTTParty.get(query)
				if status.parsed_response["#{ls.video_id}"].nil?
					ls.deleted_from_fb!
				else
					query_with_user_token = "https://graph.facebook.com/v2.8/?ids=#{ls.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{ls.user.token}"
					status = HTTParty.get(query_with_user_token)
					if status.ok?
						ls.network_error!
					else
						ls.user_session_invalid!
					end
				end
			end
    rescue Exception => e
      puts e.class,e.message
    end
	end

	def self.update_caption_for_site_credits
		live_posts = live.select{|x| ((x.user.member?)&&(!Constant::RTMP_TEMPLATE_IDS.include?(x.template.id)))}
		live_posts.each do |p|
			begin
				query = "https://graph.facebook.com/v2.8/#{p.video_id}?fields=description&access_token=#{p.user.token}"
				current_status = HTTParty.get(query).parsed_response["description"]
				caption_suffix = p.post.default_message
				if current_status.match(caption_suffix).nil?
					new_caption =  "#{current_status} \n #{caption_suffix}"
					query = "https://graph.facebook.com/v2.8/#{p.live_id}"
					response = HTTParty.post(query,:query => {"description" => "#{new_caption}", "access_token" => "#{p.user.token}"})
				end
			rescue Exception => e
				puts e.message
			end
		end
	end

	def test
		byebug
	end
end
