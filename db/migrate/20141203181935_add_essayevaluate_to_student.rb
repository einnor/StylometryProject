class AddEssayevaluateToStudent < ActiveRecord::Migration
  def change
    add_column :students, :essayEvaluate, :string
  end
end
