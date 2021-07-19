describe Review do
  let(:review) { Review.first }

  before do
    game = Game.create(title: "Mario Kart", platform: "Switch", genre: "Racing", price: 60)
    Review.create(score: 8, comment: "A classic", game_id: game.id)
  end
  
  it "has the correct columns in the reviews table" do
    expect(review).to have_attributes(score: 8, comment: "A classic", game_id: Game.first.id)
  end

  it "knows about its associated game" do
    game = Game.find(review.game_id)

    expect(review.game).to eq(game)
  end

  it "can create an associated game using the game instance" do
    game = Game.first
    review = Review.create(score: 10, comment: "10 stars", game: game)
    
    expect(review.game).to eq(game)
  end

  it "can create an associated game with the #create_game method" do
    expect do
      review = Review.create(score: 8, comment: "wow, what a game")
      review.create_game(title: "My favorite game")
      review.save
    end.to change(Game, :count).by(1)
  end
 
end
