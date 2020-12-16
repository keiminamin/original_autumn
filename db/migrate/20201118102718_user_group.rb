class UserGroup < ActiveRecord::Migration[5.2]
  def change
      create_table :usergroups do |t|
        t.references :user
        t.references :group
        t.timestamps null: false
      end
  end
end
