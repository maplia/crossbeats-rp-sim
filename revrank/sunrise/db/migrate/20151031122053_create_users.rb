class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name, :null => false
      t.string :password, :null => false
      t.string :game_id
      t.boolean :game_id_display, :default => false
      t.string :comment
      t.decimal :point, :precision => 6, :scale => 2, :default => 0.00
      t.boolean :point_direct, :default => false
      t.datetime :point_updated_at
      t.boolean :display, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
