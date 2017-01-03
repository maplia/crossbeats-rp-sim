$LOAD_PATH << '../../comrank/lib'
require 'cxbrank/const'

class ChangeUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.integer :rank_tops
    end
  end

  def self.down
    drop_column :users, :rank_tops
  end
end
