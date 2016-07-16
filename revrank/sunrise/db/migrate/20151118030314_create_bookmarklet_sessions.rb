class CreateBookmarkletSessions < ActiveRecord::Migration
  def self.up
    create_table :bookmarklet_sessions do |t|
      t.references :user, :null => false
      t.string :key
      t.integer :edit_count, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :bookmarklet_sessions
  end
end
