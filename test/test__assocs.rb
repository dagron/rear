module RearTest__Assocs
  class Books < E
    include Rear
    model Book
  end

  class Authors < E
    include Rear
    model Author
  end

  class Genres < E
    include Rear
    model Genre
  end

  Spec.new Authors do
    Books.mount

    book, book_id = new_book()
    args = [
      :reverse_assoc,
      RearTest__Assocs::Books,
      :belongs_to,
      :author,
      book_id
    ]

    Ensure 'no author attached' do
      get app.route(*args, :attached)
      is(last_response).ok?
      are(extract_elements).empty?
    end

    author = Author.create(name: rand(2**64).to_s)

    Should 'attach given author' do
      post app.route(*args, target_item_id: author.id.to_s)
      is(last_response).ok?

      Ensure 'model updated' do
        book.reload
        expect(book.author_id) == author.id
      end

      Ensure 'frontend reflects updates' do
        get app.route(*args, :attached)
        is(last_response).ok?
        expect { extract_elements.children }.any? do |c|
          c.text == author.name.to_s
        end
      end
    end

    Should 'detach given author' do
      delete app.route(*args)

      Ensure 'model updated' do
        book.reload
        refute(book.author_id) == author.id
      end

      Ensure 'frontend reflects updates' do
        get app.route(*args, :attached)
        is(last_response).ok?
        are(extract_elements).empty?
      end
    end
  
  end

  Spec.new Genres do

    book, book_id = new_book()
    args = [
      :reverse_assoc,
      RearTest__Assocs::Books,
      :has_many,
      :genres,
      book_id
    ]

    Ensure 'no genres attached' do
      get app.route(*args, :attached)
      is(last_response).ok?
      are(extract_elements).empty?
    end

    genre = Genre.create(name: rand(2**64).to_s)

    Should 'attach given genre' do
      post app.route(*args, target_item_id: genre.id.to_s)

      Ensure 'model updated' do
        book.reload
        does(book.genres).include? genre
      end

      Ensure 'frontend reflects updates' do
        get app.route(*args, :attached)
        is(last_response).ok?
        expect { extract_elements.children }.any? do |c|
          c.text == genre.name.to_s
        end
      end

    end

    Should 'detach given genre' do
      delete app.route(*args, target_item_id: genre.id.to_s)

      Ensure 'model updated' do
        book.reload
        refute(book.genres).include? genre
      end

      Ensure 'frontend reflects updates' do
        get app.route(*args, :attached)
        is(last_response).ok?
        are(extract_elements).empty?
      end
    end
  end

  class CustomKeys
    class Child < E
      include Rear
      model City
    end

    class Parent < E
      include Rear
      model State
    end
  end

  Spec.new CustomKeys::Parent do
    CustomKeys::Child.mount

    state = State.create(name: 'California', code: 'CA')
    city  = City.create
    args  = [
      :reverse_assoc,
      CustomKeys::Child,
      :belongs_to,
      :state,
      city.id
    ]

    Should 'set state to CA' do
      post app.route(*args, target_item_id: state.id.to_s)

      Ensure 'city updated' do
        city.reload
        expect(city.state_code) == state.code
      end

      Ensure 'frontend reflects updates' do
        get app.route(*args, :attached)
        is(last_response).ok?
        expect { extract_elements.children }.any? do |c|
          c.text == state.name
        end
      end

    end
  end

  Spec.new CustomKeys::Child do

    state  = State.create(name: 'New York', code: 'NY')
    cities = ['Fulton', 'Niagara Falls'].map {|c| City.create(name: c)}
    args   = [
      :reverse_assoc,
      CustomKeys::Parent,
      :has_many,
      :cities,
      state.id
    ]

    Should 'attach cities to New York' do
      cities.each do |city|
        post app.route(*args, target_item_id: city.id.to_s)
      end

      Ensure 'cities updated' do
        cities.each do |city|
          city.reload
          is(city.state_code) == state.code
        end
      end

      Ensure 'frontend reflects updates' do
        get app.route(*args, :attached)
        is(last_response).ok?
        cities_html = extract_elements.children
        cities.each do |city|
          expect(cities_html).any? do |c|
            c.text == city.name
          end
        end
      end
    end

  end

  module ReadOnly
    class Books < E
      include Rear
      model Book
      readonly_assoc :author
    end
    class Authors < E
      include Rear
      model Author
    end
    Spec.new Authors do
      Books.mount

      book, book_id = new_book()
      args = [
        :reverse_assoc,
        Books,
        :belongs_to,
        :author,
        book_id
      ]

      Ensure 'no author attached' do
        get app.route(*args, :attached)
        is(last_response).ok?
        are(extract_elements).empty?
      end

      author = Author.create(name: rand(2**64).to_s)

      Should 'prohibit attaching' do
        post app.route(*args, target_item_id: author.id.to_s)
        is(last_response).readonly_error?
      end

      Should 'prohibit detaching' do
        delete app.route(*args)
        is(last_response).readonly_error?
      end
    end
  end

end
