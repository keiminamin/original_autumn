class CreateBoards < ActiveRecord::Migration[5.2]
  def change
    create_table :boards do |t|
      t.references :user
      t.references :group
      t.string :board_title
      t.string :board_content
      t.boolean  :complete , default: false
      t.integer :custome_id
      t.string :qr_img
      t.timestamps null: false
    end
  end
end
