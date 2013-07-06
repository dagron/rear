connection = Sequel.sqlite
Sequel::Model.db = connection

connection.create_table :books_genres do |t|
  t.integer :book_id
  t.integer :genre_id
end

connection.create_table :genres do |t|
  primary_key :id
  t.string :name
end

connection.create_table :authors do |t|
  primary_key :id
  t.string :name
end

connection.create_table :books do |t|
  primary_key :id
  t.integer :author_id
  t.string  :name
  t.text    :about
  t.string  :cover
  t.string  :colors
  t.date    :created_at
end

connection.create_table :states do |t|
  primary_key :id
  t.string :name
  t.string :code
end

connection.create_table :cities do |t|
  primary_key :id
  t.string :name
  t.string :state_code
end

class Author < Sequel::Model
end

class Genre < Sequel::Model
end

class Book < Sequel::Model
  many_to_one :author
  many_to_many :genres
end

class State < Sequel::Model
  one_to_many :cities, key: :state_code, primary_key: :code
end

class City < Sequel::Model
  many_to_one :state, key: :state_code, primary_key: :code
end
