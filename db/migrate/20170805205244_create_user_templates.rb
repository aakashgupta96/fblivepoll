class CreateUserTemplates < ActiveRecord::Migration
  def change
    create_table :user_templates do |t|
      t.integer :user_role
      t.integer :template_id

      t.timestamps null: false
    end
  end
end
