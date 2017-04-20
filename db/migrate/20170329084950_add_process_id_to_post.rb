class AddProcessIdToPost < ActiveRecord::Migration
  def change
    add_column :posts, :process_id, :string
  end
end
