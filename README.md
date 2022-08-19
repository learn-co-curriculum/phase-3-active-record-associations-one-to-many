# One To Many Associations

## Learning Goals

- Understand how and why Active Record implements associations between models
- Use Active Record migrations and methods to build out a domain model that
  associates classes
- Establish the one-to-many (or **has-many/belongs-to**) association in Active
  Record

## Introduction

We already know that we can build our SQL tables such that they associate with
one another via **primary keys** and **foreign keys**. We can also use Active
Record to access data across different tables by establishing associations in
code, without having to write tons of code ourselves, following the idea of
**convention over configuration**.

Active Record associations make it easy to establish relationships between our
models, without having to write a ton of SQL ourselves. Sounds great, right? Now
that we have you totally hooked, let's take a look at how we use these Active
Record associations.

## How do we use Active Record Associations?

Active Record makes it easy to implement one-to-many and many-to-many
relationships between multiple models. In order to implement these
relationships, we will need to do two things:

1. Write a migration that creates tables with associations. For example, if a
   cat belongs to an owner, the cats table should have an `owner_id` column.
2. Use Active Record **macros** in the models to generate additional methods
   that use the relationship between two database tables.

## Overview

In this lesson, we'll be building out a **one-to-many** relationship between two
models: **games** and **reviews**. We'll set up our database so that a game
**has many** reviews, and each review **belongs to** a specific game.

By writing a few migrations and making use of the appropriate Active Record
macros (more on that later), we will be able to:

- ask a game about its reviews
- ask a review about its game

Here's what our Entity Relationship Diagram (ERD) looks like:

![Game Reviews ERD](https://curriculum-content.s3.amazonaws.com/phase-3/active-record-associations-one-to-many/games-reviews-erd.png)

We will build these associations through the use of Active Record migrations and
macros.

## Building our Migrations

### The Game Model

A game will _have many_ reviews. Before we worry about the migration that will
implement this in our reviews table, let's think about what that table will look
like:

| id  | title              | genre            | platform   | price |
| --- | ------------------ | ---------------- | ---------- | ----- |
| 1   | Breath of the Wild | Action-adventure | Switch     | 60    |

Our games table doesn't need any information about the reviews, so it makes
sense to generate this table first: it doesn't have any dependencies on another
table. This makes sense even thinking about our domain in the real world: a game
can exist without any reviews.

Let's write the migration that will make this happen. Run this code to create
a migration:

```console
$ bundle exec rake db:create_migration NAME=create_games
```

In the migration file, write the following migration:

```rb
class CreateGames < ActiveRecord::Migration[6.1]
  def change
    create_table :games do |t|
      t.string :title
      t.string :genre
      t.string :platform
      t.integer :price
      t.timestamps
    end
  end
end
```

### The Review Model

A review will **belong to** a specific game. What does that mean in terms of our
database? Think back to what you learned about SQL and joining between multiple
tables. How can we connect between a review and its associated game?

That's right, we need a **foreign key**! Since a review belongs to a specific
game, we need some way of indicating on the review _which_ specific game it
belongs to.

Let's take a look at what our `reviews` table will need to look like:

| id  | score | comment    | game_id |
| --- | ----- | ---------- | ------- |
| 1   | 10    | A classic! | 1       |

Notice we're using a `game_id` column to create a foreign key relationship with
the `games` table. This naming convention is **very important**, as we'll see
later: in order for Active Record to correctly understand the relationship
between our tables, the **foreign key's name must match the name of the table
where the primary key is located**.

This is another place where following convention over configuration will allow
Active Record to do a lot of work for us under the hood without us needing
to write much code, so it bears repeating:

In order for Active Record to correctly understand the relationship between our
tables, the **foreign key's name must match the name of the table where the
primary key is located**. For a `games` table, we create a `game_id` foreign
key.

Ok! Now that we know what we need to create, let's run this code to create a
migration:

```console
$ bundle exec rake db:create_migration NAME=create_reviews
```

In the migration file:

```rb
class CreateReviews < ActiveRecord::Migration[6.1]
  def change
    create_table :reviews do |t|
      t.integer :score
      t.string :comment
      t.integer :game_id # this is our foreign key
      t.timestamps
    end
  end
end
```

Great! Now go ahead and run the following command in your terminal to
run our migrations:

```console
$ bundle exec rake db:migrate
```

There is also some code in the `db/seeds.rb` file that we'll use to generate
some data for our two models. In the seed file, we first create a game instance,
then use the ID from that game instance to associate it with the corresponding
review.

Run this to seed the database:

```console
$ bundle exec rake db:seed
```

## Building our Associations using Active Record Macros

### What is a macro?

A macro is a method that writes code for us (think metaprogramming). You've used
macros like `attr_reader` and `attr_accessor` already. Active Record comes with
a few handy macros that, like `attr_reader` and `attr_accessor`, create new
instance methods we can use with our classes.

By invoking a few methods that come with Active Record, we can implement all of
the associations we've been discussing!

We'll be using the following Active Record macros (or methods):

- [`has_many`][]
- [`belongs_to`][]

[`has_many`]: http://guides.rubyonrails.org/association_basics.html#the-has-many-association
[`belongs_to`]: http://guides.rubyonrails.org/association_basics.html#the-belongs-to-association

Let's get started.

### A Review Belongs to a Game

Our `Review` class is set up in `app/models/review.rb`. Notice that it inherits from
`ActiveRecord::Base`. This is very important! If we don't inherit from
`ActiveRecord::Base`, we won't get our fancy macro methods.

```rb
class Review < ActiveRecord::Base

end
```

Let's start by talking through the code we want to be able to write here. Hop
into your console by running:

```console
$ bundle exec rake console
```

From the console, access the first review:

```rb
# Access the first review instance in the database
review = Review.first
# => #<Review:0x00007ffc23c58e20 id: 1, score: 6, comment: "Velit a tenetur eius.", game_id: 1>

# Get the game_id foreign key for the review instance
review.game_id
# => 1
```

We know that this review has some relationship to data in the `games` table. We
could even use the foreign key to access that data directly:

```rb
# Find a specific game instance using an ID
Game.find(review.game_id)
# => #<Game:0x00007ffc2801e4e8 id: 1, title: "Metroid Prime", ...>
```

But it would be convenient to be able to access the game directly, by calling an
instance method on the review itself. For instance, imagine we're building a
website that shows game reviews. Wouldn't it be nice to have an easy way to
access all the data about the game that's being reviewed, even though that
information is stored in another table?

We could write an instance method ourselves in the `Review` class to establish
this relationship. Exit the console, then add this to your `Review` class:

```rb
class Review < ActiveRecord::Base
  # a review belongs to a game
  def game
    # self is the review instance
    Game.find(self.game_id)
  end

end
```

Then run `rake console` again. Now we can access any review's associated game
directly by using this new instance method:

```rb
Review.first.game
# => #<Game:0x00007ffc2801e4e8 id: 1, title: "Metroid Prime", ...>
Review.last.game
# => #<Game:0x00007f9c68130d38 id: 50, title: "Max Payne", ...>
```

Nice! However, since this is such a common task we'll need to perform, Active
Record makes our lives a bit easier. This is where those macros come into play.

Let's update the `Review` class to use the `belongs_to` macro instead of our
custom method:

```rb
class Review < ActiveRecord::Base
  belongs_to :game
end
```

Now, exit the console and open it again to reload your code, and try using
the `#game` instance method:

```rb
Review.first.game
# => #<Game:0x00007ffc2801e4e8 id: 1, title: "Metroid Prime", ...>
Review.last.game
# => #<Game:0x00007f9c68130d38 id: 50, title: "Max Payne", ...>
```

As you can see, this method does the same job as our custom instance method,
but with less work on our part. Thanks, Active Record!

A couple notes on this code. While it seems like a lot of magic is happening in
order for us to write `belongs_to :game` and have Active Record take care of
establishing the connection between our classes, remember, this is all just Ruby
code. `belongs_to` is a method that is inherited from `ActiveRecord::Base` that
takes an argument of a symbol:

```rb
class Review < ActiveRecord::Base
  belongs_to(:game)
end
```

We just call the method without parentheses because it looks nicer.

Also, the name of the symbol we are passing to `belongs_to` must be
**singular**: this is another important convention to follow so that all this
"magic" works.

When we use the association methods, Active Record generates some SQL code like
this to access the data from the correct tables:

```sql
SELECT "games".*
FROM "games"
WHERE "games"."id" = 1
LIMIT 1;
```

### A Game Has Many Reviews

Our `Game` class is set up in `app/models/game.rb`. We need to tell the
`Game` class that each game instance can have many reviews. We will use the
`has_many` macro to do it:

```rb
class Game < ActiveRecord::Base
  has_many :reviews

end
```

Just like with `belongs_to`, following naming conventions is important: we use
the **plural** for the `has_many` macro.

And that's it! Now, because our `reviews` table has a `game_id` column and
because our `Game` class uses the `has_many` macro, we can easily access a list
of all reviews associated with any game! What this means in code is that we can
now use the `#reviews` instance method to return a list of all the reviews
belonging to a game:

```rb
game = Game.first
game.reviews
# => [#<Review:0x00007f9ddcaa8198 id: 1, score: 6, ...,  #<Review:0x00007f9de1612610 id: 2, score: 8, ...>, ...]
game.reviews.count
# 4
```

If we were to write this `#reviews` instance method out by hand, it'd look
something like this:

```rb
class Game < ActiveRecord::Base

  def reviews
    Review.where(game_id: self.id)
  end

end
```

Again, by following conventions with our table names and foreign key names, we
can use the macro to save us from writing this code out by hand.

Here's the SQL that Active Record generates for this query:

```sql
SELECT "reviews".*
FROM "reviews"
WHERE "reviews"."game_id" = 1
```

Once again, we're using the same primary key/foreign key relationship between
these two tables to establish this connection.

## Our Code in Action: Working with Associations

All the tests should be passing now if you run `learn test`, so from here on
we'll just be exploring the functionality provided by the `has_many` and
`belongs_to` macros. Follow along with this code by running:

```console
$ bundle exec rake console
```

To recap what we've seen so far:

Using the `belongs_to :game` macro in our `Review` class generates an instance
method, `#game` that we can use to access the data about a game from the review:

```rb
# Get a review instance
review = Review.first
# call the #game instance method to return a Game instance
review.game
# => #<Game:0x00007f9de1710be8 id: 1, title: "Metroid Prime",...>
```

Using the `has_many :reviews` macro in our `Game` class generates an instance
method, `#reviews` that we can use to access the data about reviews from the game:

```rb
# Get a game instance
game = Game.first
# call the #reviews instance method to return a list of Review instances
game.reviews
# => [#<Review:0x00007f9ddcb09100 id: 1, score: 6, ...>, #<Review:0x00007f9ddcb08f98 id: 2, score: 8, ...>]
```

In addition to these instance methods, both the `has_many` and `belongs_to`
macros also provide some additional functionality to our classes.

For example, after adding the `belongs_to` macro to our `Review` class, we can
also more easily create new reviews that are associated with a game instance.
You can see all the methods that Active Record provides in the
[documentation on `belongs_to`][belongs_to methods].

Previously, we'd need to create our `Review` instances like this:

```rb
game = Game.first
Review.create(score: 10, comment: "10 stars", game_id: game.id)
```

After adding the `belongs_to` macro, we can also create new reviews by passing
a `Game` instance directly, instead of passing the foreign key:

```rb
game = Game.first
Review.create(score: 10, comment: "10 stars", game: game)
```

In both cases, Active Record will generate the same SQL, so it is still using
the `game_id` foreign key under the hood:

```sql
INSERT INTO "reviews" ("score", "comment", "game_id", "created_at", "updated_at") VALUES (?, ?, ?, ?, ?)
```

We can also use the `create_game` method to generate a new game from
scratch and automatically associate it with a review:

```rb
# Create a review
review = Review.create(score: 8, comment: "wow, what a game")
# Create a game associated with the review
review.create_game(title: "My favorite game")
# Save the association
review.save
```

This will insert a row into the `reviews` table, then insert a row into the
`games` table, and finally, update the review with the foreign key of the
newly-created game.

On the flip side, the `has_many` macro also provides some additional methods for
the `Game` class. You can see them all in the
[`has_many` docs][has_many methods]. One commonly used method from the
`has_many` macro is the shovel (`<<`) method, which lets us generate a new
review and associate it with an existing game:

```rb
game = Game.first
game.reviews << Review.new(score: 3, comment: "meh")
```

This will insert a new row in the `reviews` table and give it a foreign key for
the game instance.

It also generates a `#create` method via the association:

```rb
game = Game.first
game.reviews.create(score: 4, comment: "it's alright I guess")
```

This method essentially does the same as the shovel method.

There are other methods provided as well that will help with different CRUD
actions related to the associations, so make sure to reference the
[documentation][ar-associations] when the need arises!

## Conclusion

In this lesson, we explored the most common kind of relationship between two
models: the **one-to-many** or "has-many"/"belongs-to" relationship. With a
solid understanding of how to connect databases using primary and foreign keys,
we can take advantage of some helpful Active Record macros that make it easy to
work with the database relationships from our Ruby code.

## Resources

- [Active Record Associations][ar-associations]
- [belongs_to methods][]
- [has_many methods][]

[ar-associations]: https://guides.rubyonrails.org/association_basics.html
[belongs_to methods]: https://guides.rubyonrails.org/association_basics.html#methods-added-by-belongs-to
[has_many methods]: https://guides.rubyonrails.org/association_basics.html#methods-added-by-has-many
