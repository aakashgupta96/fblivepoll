class CreateSharedPosts < ActiveRecord::Migration
  def change
    create_table :shared_posts do |t|
      t.string :shared_post_id
      t.integer :post_id

      t.timestamps null: false
    end
  end
end
