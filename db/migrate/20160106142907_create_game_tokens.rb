class CreateGameTokens < ActiveRecord::Migration
  def change
    create_table :game_tokens do |t|
      t.string :description
      t.string :code

      t.timestamps
    end
  end
end
