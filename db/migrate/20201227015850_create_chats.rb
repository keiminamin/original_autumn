class CreateChats < ActiveRecord::Migration[5.2]
  def change
    create_table :chats do |t|
      t.references :board
      t.integer :user_id
      t.text  :message
    end
  end
end
