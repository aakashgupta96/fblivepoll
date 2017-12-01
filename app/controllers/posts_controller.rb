class PostsController < ApplicationController
	before_action :set_post
  before_action :authenticate_user!
  before_action :authorize_user!

  def share_select
  	@pages = current_user.pages
  end

  def share
  	selected_pages = Array.new()
  	params["page"].each do |page_id,value|
  		selected_pages << page_id if value == "on"
  	end unless params["page"].nil?
  	if @post.share_on(selected_pages)
  	 return redirect_to "/posts/#{@post.id}", notice: "Post shared successfully"
    else
      return redirect_to "/posts/#{@post.id}", notice: "There occurred some error while sharing post."
    end
  end

  def show
    response = HTTParty.get("https://graph.facebook.com/#{@post.page_id}?fields=name,picture{url}&access_token=#{@post.user.token}")
    @url = response.parsed_response["picture"]["data"]["url"] rescue false
    @name = response.parsed_response["name"]
    return redirect_to myposts_path, notice: Constant::INVALID_OPERATION_MESSAGE if @post.nil?
  end

  def submit
  end
  
end