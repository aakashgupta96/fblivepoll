class ExtrasController < ApplicationController
	
	def invalid
    redirect_to root_path, notice: "Page requested not found"
  end

  def home    
  end
  
	def privacy
	end
	
	def terms
	end

	def demo
	end

	def donation
	end

end