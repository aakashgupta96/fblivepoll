class AdminsController < ApplicationController
	before_action :authenticate_admin!

	def dashboard
		@posts = Post.live
	end

	def stop
		Post.find(params[:post_id]).stop
		redirect_to '/admins/dashboard'
	end
end
