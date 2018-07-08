class AddTypeToLiveStream < ActiveRecord::Migration
  
  def change
    add_column :live_streams, :target, :integer, default: 0
    LiveStream.all.each do |ls|
      if ls.page_id.nil?
        ls.other!
      else
        ls.on_page!
      end
    end
  end

end
