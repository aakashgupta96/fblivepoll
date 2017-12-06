class SharedPost < ActiveRecord::Base
	belongs_to :post
	delegate :user, to: :post
end
