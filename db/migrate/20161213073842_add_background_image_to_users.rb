class AddBackgroundImageToUsers < ActiveRecord::Migration
  def change
    add_column :posts, :background_image, :string
  end
end
