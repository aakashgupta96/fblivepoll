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
  	@post.share_on(selected_pages)
  	return redirect_to "/posts/#{@post.id}", notice: "Post shared successfully"
  end
  
end