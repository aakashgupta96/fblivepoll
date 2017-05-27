class AddReloadBrowserToPost < ActiveRecord::Migration
  def change
    add_column :posts, :reload_browser, :boolean, default: false
  end
end
