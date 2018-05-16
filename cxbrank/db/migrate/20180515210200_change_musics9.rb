class ChangeMusics9 < ActiveRecord::Migration[4.2]
  def self.up
    change_table :musics do |t|
      t.string :csv_id
    end
    add_index :musics, :csv_id, unique: true
  end

  def self.down
    remove_column :musics, :csv_id
    remove_index :musics, :csv_id
  end
end
