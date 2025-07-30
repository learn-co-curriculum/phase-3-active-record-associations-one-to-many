class CreateReviews < ActiveRecord::Migration[8.0]
  def change
      create_table :reviews do |t|
      t.integer :score
      t.string :comment
      t.integer :game_id 
      t.timestamps
    end
  end
end
