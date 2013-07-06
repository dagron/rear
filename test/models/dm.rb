DataMapper.setup :default, 'sqlite::memory:'

class Author
  include DataMapper::Resource

  property :id,    Serial
  property :name,  String
end

class Genre
  include DataMapper::Resource

  property :id,    Serial
  property :name,  String

  has n, :books, through: Resource
end

class Book
  include DataMapper::Resource

  property :id,     Serial
  property :name,   String
  property :about,  Text
  property :cover,  String
  property :colors, String
  property :created_at, Date

  belongs_to :author, required: false
  has n,     :genres, through:  Resource
end

class State
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, index: true
  property :code, String, unique: true, length: 2

  has n, :cities, child_key: :state_code, parent_key: :code
end

class City
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, index: true

  belongs_to :state, child_key: :state_code, parent_key: :code, required: false
end

DataMapper.finalize
DataMapper.auto_migrate!
