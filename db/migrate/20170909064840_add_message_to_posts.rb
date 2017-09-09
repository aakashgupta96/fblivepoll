class AddMessageToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :default_message, :text, default: "To make something like this, visit www.shurikenlive.com"
  end
end
