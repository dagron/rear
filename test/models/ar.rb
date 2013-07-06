ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

class Author < ActiveRecord::Base
end

class Genre < ActiveRecord::Base
end

class Book < ActiveRecord::Base
  belongs_to :author
  has_and_belongs_to_many :genres
end

class State < ActiveRecord::Base
  has_many :cities, foreign_key: :state_code, primary_key: :code
end

class City < ActiveRecord::Base
  belongs_to :state, foreign_key: :state_code, primary_key: :code
end

ActiveRecord::Migration.create_table :books_genres do |t|
  t.integer :book_id
  t.integer :genre_id
end

ActiveRecord::Migration.create_table :genres do |t|
  t.string :name
end

ActiveRecord::Migration.create_table :authors do |t|
  t.string :name
end

ActiveRecord::Migration.create_table :books do |t|
  t.integer :author_id
  t.string  :name
  t.text    :about
  t.string  :cover
  t.string  :colors
  t.date    :created_at
end

ActiveRecord::Migration.create_table :states do |t|
  t.string :name
  t.string :code
end

ActiveRecord::Migration.create_table :cities do |t|
  t.string :name
  t.string :state_code
end
