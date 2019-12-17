class AddIssuePosition < ActiveRecord::Migration[5.0]
  def self.up
    add_column :issues, :ir_position, :integer, :null => true, :default => nil
    add_index :issues, :ir_position
  end

  def self.down
    remove_column :issues, :ir_position
  end
end
