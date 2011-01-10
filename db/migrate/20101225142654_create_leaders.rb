class CreateLeaders < ActiveRecord::Migration
  def self.up
    create_table :leaders do |t|
      t.string :name
      t.integer :nation_id

      t.timestamps
    end
  end

  def self.down
    drop_table :leaders
  end
end
