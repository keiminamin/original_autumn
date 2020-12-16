class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :name
      t.string :password_digest
      t.string :qr_img
      t.integer :evaluation, default: 10
      t.integer :point, default:  10
      t.timestamps null: false
    end
  end
end
