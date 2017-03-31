class AddReactionToImages < ActiveRecord::Migration
  def change
  	add_column :images, :reaction , :string
  end
end
