class ExtrasController < ApplicationController
	
	def invalid
    redirect_to root_path, notice: "Page requested not found"
  end

  def home
		@templates = Template.all.order(id: :desc)
  end
  
	def privacy
	end
	
	def terms
	end

	def demo
	end

	def pricing
	end

	def ask_question
		Resque.enqueue(NotifyAdmins,params[:username],params[:phone],params[:email],params[:message])
    respond_to do |format|
      format.js
    end
	end

end