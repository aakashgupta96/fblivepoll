class AdminsController < ApplicationController
	before_action :authenticate_admin!

	def dashboard
		@posts = Post.all.order(id: :desc)
	end

	def stop_post
		Post.find(params[:post_id]).stop("Stopped by admin")
		redirect_to '/admins/dashboard', notice: "Live Video has been successfully stopped."
	end
end
