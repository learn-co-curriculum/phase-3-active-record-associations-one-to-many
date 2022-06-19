class Review < ActiveRecord::Base

  belongs_to :game
  # def game 
  #   Game.find(self.game_id)
  # end
end
