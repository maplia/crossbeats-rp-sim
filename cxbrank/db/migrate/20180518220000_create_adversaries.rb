$LOAD_PATH << '../comrank/lib'
require 'cxbrank/const'
require 'cxbrank/user'

class CreateAdversaries < ActiveRecord::Migration[4.2]
  def self.up
    create_table :adversaries do |t|
      t.references :user, :foreign_key => true, :null => false
      t.references :adversary, :foreign_key => {:to_table => :users}, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :adversaries
  end
end
