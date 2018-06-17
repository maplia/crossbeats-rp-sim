class ChangeUsers2 < ActiveRecord::Migration[4.2]
  def self.up
    change_table :users do |t|
      t.boolean :whole, :default => true
      t.boolean :legacy, :default => true
    end
  end

  def self.down
    remove_column :users, :whole
    remove_column :users, :legacy
  end
end
