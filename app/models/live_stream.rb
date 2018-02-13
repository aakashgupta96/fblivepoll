class LiveStream < ActiveRecord::Base
	belongs_to :post
	delegate :user, to: :post
	delegate :template, to: :post
	has_many :shared_posts, dependent: :destroy
	has_many :messages
	enum status: [:drafted, :published, :scheduled, :stopped_by_user, :request_declined, :deleted_from_fb, :network_error, :unknown, :queued, :live, :schedule_cancelled, :user_session_invalid]

	def live_on_fb?
		unless Constant::RTMP_TEMPLATE_IDS.include?(template.id)
			query = "https://graph.facebook.com/v2.8/#{video_id}?fields=live_status&access_token=#{user.token}"
			response = HTTParty.get(query)
			if response.ok?
				return response.parsed_response["live_status"] == "LIVE"
			else
				return false
			end
		else
			return false
		end
	end

	def exists_on_fb?
		unless Constant::RTMP_TEMPLATE_IDS.include?(template.id)
			query = "https://graph.facebook.com/v2.8/#{video_id}?access_token=#{user.token}"
			response = HTTParty.get(query)
			return response.ok?
		else
			return false
		end
	end


	def ended_on_fb?
		unless Constant::RTMP_TEMPLATE_IDS.include?(template.id)
			query = "https://graph.facebook.com/v2.8/#{video_id}?fields=live_status&access_token=#{user.token}"
			response = HTTParty.get(query)
			possible_values = ["PROCESSING","VOD", "LIVE_STOPPED"]
			if response.ok?
				return possible_values.include?(response.parsed_response["live_status"])
			else
				return true
			end
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
					video = graph.graph_call("#{page_id}/live_videos",{status: "UNPUBLISHED", description: "#{post.caption}#{caption_suffix}", title: post.title, stream_type: "AMBIENT"},"post")
				else
					video = graph.graph_call("#{page_id}/live_videos",{status: "UNPUBLISHED", description: "#{post.caption}#{caption_suffix}", title: post.title},"post")
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

	def mark_live_on_fb
		unless Constant::RTMP_TEMPLATE_IDS.include?(template.id)
			begin
				graph = graph_with_page_token
				video = graph.graph_call("#{live_id}",{status: "LIVE_NOW"},"post")
			  return true
			rescue Exception => e
				puts e.class,e.message
	      request_declined!
				return false
			end
		else
			return true
		end
	end

	def cancel_schedule
		destroy if scheduled?
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

	def update_status #Can change status to deleted, published and session invalid state
		if Constant::RTMP_TEMPLATE_IDS.include?(template.id)
			self.published!
			return
		end
		begin
			query_from_app = "https://graph.facebook.com/v2.8/#{video_id}?access_token=#{ENV['FB_ACCESS_TOKEN']}"
			query_from_user = "https://graph.facebook.com/v2.8/#{video_id}?access_token=#{user.token}"
			status_from_app = HTTParty.get(query_from_app)
			status_from_user = HTTParty.get(query_from_user)
			if status_from_app.ok? and status_from_user.ok?
				self.published!
			elsif status_from_app.ok?
				self.user_session_invalid!
			else
				self.deleted_from_fb!
			end
		rescue Exception => e
			puts e.class,e.message
		end
	end

	def share_on(page_ids)
		begin
			attempts = 0
			url = "https://www.facebook.com/" + video_id
			user_graph = Koala::Facebook::API.new(user.token)
			page_ids.each do |page_id|
				begin
					access_token = user_graph.get_page_access_token(page_id)
					graph = Koala::Facebook::API.new(access_token)
					response = graph.put_wall_post("",link: url)
					self.shared_posts << SharedPost.create(shared_post_id: response["id"])
				rescue Exception => e
					puts e.message
					attempts += 1
					retry if attempts <= 3
					raise e
				end
			end
		rescue Exception => e
			puts e.message
			return false
		end
		return true
	end

	def self.update_statuses	
		begin
			#Required when some live streams of post are ended from fb end
			live.each do |ls|
				ls.update_status if ls.ended_on_fb?
			end

			# stopped_by_user.each do |ls|
			# 	ls.update_status
			# end
			unknown.each do |ls|
				if Constant::RTMP_TEMPLATE_IDS.include?(ls.template.id)
					ls.published!
					next
				end
				query_from_app = "https://graph.facebook.com/v2.8/#{ls.video_id}?access_token=#{ENV['FB_ACCESS_TOKEN']}"
				query_from_user = "https://graph.facebook.com/v2.8/#{ls.video_id}?access_token=#{ls.user.token}"
				status_from_app = HTTParty.get(query_from_app)
				status_from_user = HTTParty.get(query_from_user)
				if status_from_app.ok? and status_from_user.ok?
					ls.network_error! #Can it be changed to published ?
				elsif status_from_app.ok?
					ls.user_session_invalid!
				else
					ls.deleted_from_fb!
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

	def self.get_details
		temp = Hash.new()
    attempts = 0
    page_ids = pluck(:page_id)
    return temp if page_ids.empty?
    begin
      graph = Koala::Facebook::API.new(ENV["FB_ACCESS_TOKEN"])
      query = "?ids=#{page_ids.first(49).join(',')}&fields=picture{url},name"
      response = graph.get_object(query)
      response.each do |page_attrs|
        page_hash = {"name"=> page_attrs.second["name"], "id" => page_attrs.second["id"], "image" => page_attrs.second["picture"]["data"]["url"]}
        temp[page_hash["id"]] = page_hash
      end
      temp
    rescue Exception => e
    	attempts += 1
      retry if attempts <= 3
      raise e
    end 
	end
	
end
