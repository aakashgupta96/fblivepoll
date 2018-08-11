class LiveStream < ActiveRecord::Base
	belongs_to :post
	delegate :user, to: :post
	delegate :template, to: :post
	has_many :shared_posts, dependent: :destroy
	has_many :messages
	enum status: [:drafted, :published, :scheduled, :stopped_by_user, :request_declined, :deleted_from_fb, :network_error, :unknown, :queued, :live, :schedule_cancelled, :user_session_invalid]
  enum target: [:on_page, :on_group, :on_timeline, :other]

	def live_on_fb?
		unless Constant::RTMP_TEMPLATE_IDS.include?(template.id)
			query = "https://graph.facebook.com/v3.0/#{video_id}?fields=live_status&access_token=#{user.token}"
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

	def ended_on_fb?
		unless Constant::RTMP_TEMPLATE_IDS.include?(template.id)
			query = "https://graph.facebook.com/v3.0/#{video_id}?fields=live_status&access_token=#{user.token}"
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

  def get_reactions_count
    reactions = {}
    unless self.target == "other"
      query = "https://graph.facebook.com/v3.0/?ids=#{video_id}&fields=from,reactions.type(LIKE).limit(0).summary(total_count).as(like),reactions.type(LOVE).limit(0).summary(total_count).as(love),reactions.type(WOW).limit(0).summary(total_count).as(wow),reactions.type(HAHA).limit(0).summary(total_count).as(haha),reactions.type(SAD).limit(0).summary(total_count).as(sad),reactions.type(ANGRY).limit(0).summary(total_count).as(angry),comments.limit(0).summary(total_count).as(comments)&access_token=#{self.user.token}"
      status = HTTParty.get(query)
      response = status.parsed_response["#{video_id}"]
      unless response.nil?
        reactions["from"] = response["from"]["name"]
        reactions["like"] = response["like"]["summary"]["total_count"]
        reactions["love"] = response["love"]["summary"]["total_count"]
        reactions["wow"] = response["wow"]["summary"]["total_count"]
        reactions["sad"] = response["sad"]["summary"]["total_count"]
        reactions["angry"] = response["angry"]["summary"]["total_count"]
        reactions["haha"] = response["haha"]["summary"]["total_count"]
        reactions["comments"] = response["comments"]["summary"]["total_count"]
      end
    end
    reactions
  end


	def start
		if Constant::RTMP_TEMPLATE_IDS.include?(template.id) || (self.target == "other")
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
        if Rails.env.production?
          privacy = "EVERYONE"
        else
          privacy = "SELF"
        end
        if post.ambient?
					video = graph.graph_call("#{page_id}/live_videos",{privacy: {value: privacy}, status: "UNPUBLISHED", description: "#{post.caption}#{caption_suffix}", title: post.title, stream_type: "AMBIENT"},"post")
				else
					video = graph.graph_call("#{page_id}/live_videos",{privacy: {value: privacy},status: "UNPUBLISHED", description: "#{post.caption}#{caption_suffix}", title: post.title},"post")
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
		unless (Constant::RTMP_TEMPLATE_IDS.include?(template.id) || self.target == "other")
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
      self.graph_with_page_token.graph_call("#{live_id}", {end_live_video: "true"},"post") unless (Constant::RTMP_TEMPLATE_IDS.include?(template.id) || self.target == "other")
    rescue Exception => e
    	puts e.class,e.message
    end
    self.update(status: status)
	end

	def page_access_token
		attempts = 0
		begin
      if on_page?
  			graph = Koala::Facebook::API.new(user.token)
  			access_token = graph.get_page_access_token(page_id)
      else
        access_token = user.token
      end
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
		if (Constant::RTMP_TEMPLATE_IDS.include?(template.id)  || self.target == "other")
			self.published!
			return
		end
		begin
			query = "https://graph.facebook.com/v3.0/?ids=#{video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{ENV["FB_ACCESS_TOKEN"]}"
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

	def share_on(handle_ids)
    begin
			attempts = 0
			url = "https://www.facebook.com/" + video_id
      user_page_ids = Set.new()
      user.pages.each do |page|
        user_page_ids.add(page["id"])
      end
			user_graph = Koala::Facebook::API.new(user.token)
			handle_ids.each do |handle_id|
				begin
          if user_page_ids.include?(handle_id)
					 access_token = user_graph.get_page_access_token(handle_id)
          else
            access_token = user.token
          end
					graph = Koala::Facebook::API.new(access_token)
					response = graph.graph_call("#{handle_id}/feed",{link: url},"post")
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
			live.each do |ls|
				ls.update_status if ls.ended_on_fb?
			end
			unknown.each do |ls|
				if Constant::RTMP_TEMPLATE_IDS.include?(ls.template.id)
					ls.published!
					next
				end
				query = "https://graph.facebook.com/v3.0/?ids=#{ls.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{ENV["FB_ACCESS_TOKEN"]}"
				status = HTTParty.get(query)
				if status.parsed_response["#{ls.video_id}"].nil?
					ls.deleted_from_fb!
				else
					query_with_user_token = "https://graph.facebook.com/v3.0/?ids=#{ls.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{ls.user.token}"
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
				query = "https://graph.facebook.com/v3.0/#{p.video_id}?fields=description&access_token=#{p.user.token}"
				current_status = HTTParty.get(query).parsed_response["description"]
				caption_suffix = p.post.default_message
				if current_status.match(caption_suffix).nil?
					new_caption =  "#{current_status} \n #{caption_suffix}"
					query = "https://graph.facebook.com/v3.0/#{p.live_id}"
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
    begin
      graph = Koala::Facebook::API.new(self.first.user.token) #(ENV["FB_ACCESS_TOKEN"])
      page_ids = self.where.not(target: LiveStream.targets["other"]).pluck(:page_id).compact
      unless page_ids.size == 0
        query = "?ids=#{page_ids.first(49).join(',')}&fields=picture{url},name"
        response = graph.get_object(query)
        response.each do |page_attrs|
          page_hash = {"name"=> page_attrs.second["name"], "id" => page_attrs.second["id"], "image" => page_attrs.second["picture"]["data"]["url"]}
          temp[page_hash["id"]] = page_hash
        end
      end
      temp
    rescue Exception => e
    	attempts += 1
      retry if attempts <= 3
      raise e
    end 
	end
	
end
