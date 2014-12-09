class AddEvaluateToTest < ActiveRecord::Migration
  def change
    add_column :tests, :evaluate, :string
  end
end
