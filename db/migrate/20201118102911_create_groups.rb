class CreateGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :groups do |t|
        t.string :group_name
        t.string :password_digest
        t.timestamps null: false
    end
  end
end
