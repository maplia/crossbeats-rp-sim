class CreateMonthlies < ActiveRecord::Migration
	def self.up
		create_table :monthlies do |t|
			t.references :music, :null => false
			t.datetime :span_s, :null => false
			t.datetime :span_e, :null => false
			t.timestamps
		end
		change_table :monthlies do |t|
			t.index ['Music'.foreign_key, :span_s], :unique => true
		end
	end

	def self.down
		drop_table :monthlies
	end
end
