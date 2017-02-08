class ChaneColumnNameTypeToEmoticon < ActiveRecord::Migration
  def change
  	rename_column :compare_objects, :type, :emoticon
  end
end
