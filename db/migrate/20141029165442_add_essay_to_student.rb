class AddEssayToStudent < ActiveRecord::Migration
  def change
    add_column :students, :essay, :string
  end
end
