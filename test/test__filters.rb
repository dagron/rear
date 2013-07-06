
module RearTest__Filters
  NAMES = %w[
    Arthur Aaron Adler
    Daniel Dante David
    Edward Eliot Elvin
  ]
  
  class BasicQuickFilterApp < E
    include Rear
    model Book

    quick_filter :cover, :Soft, :Solid
    quick_filter :colors, 'r' => 'Red Color', 'g' => :Green
  end
  Spec.new BasicQuickFilterApp do
    
    Testing 'filters provided as arguments' do    
      %w[Soft Solid].map do |cover|
        1.upto(rand(10)+1) { app.model.create(:cover => cover) }
      end

      cover = 'Soft'
      items = count_books(:cover => cover)
      expect(items) > 0
      get quick_filters: {cover: cover}
      is(last_response).ok?
      expect(items) == extract_elements('.pane-item').size

      cover = 'Solid'
      items = count_books(cover: cover)
      expect(items) > 0
      get quick_filters: {cover: cover}
      is(last_response).ok?
      expect(items) == extract_elements('.pane-item').size
    end

    Testing 'filters provided as Hash' do
      %w[r g].map do |color|
        1.upto(rand(10)+1) { app.model.create(:colors => color) }
      end

      items = count_books( :colors => 'r')
      expect(items) > 0
      get quick_filters: {colors: 'Red Color'}
      is(last_response).ok?
      expect(items) == extract_elements('.pane-item').size

      items = count_books( :colors => 'g')
      expect(items) > 0
      get quick_filters: {colors: 'Green'}
      is(last_response).ok?
      expect(items) == extract_elements('.pane-item').size
    end

  end


  class AdvancedQuickFilterApp < E
    include Rear
    model Book

    quick_filter :name, cmp: :like_, 'A' => :StartingwithA, 'Z' => 'Starting with Z'
    quick_filter :colors, 'r' => :Red, [:like_, :g] => :GreenFirst
  end

  Spec.new AdvancedQuickFilterApp do
    query_map = RearConstants::FILTERS__QUERY_MAP.call(app.orm)

    Testing 'cmp passed as global option' do
      %w[A Z].map do |letter|
        1.upto(rand(10)+1) { app.model.create(:name => letter + random_string) }
      end

      query, value = query_map[:like_]
      items = count_books( [query % :name, value % "A"])
      expect(items) > 0
      get quick_filters: {name: 'StartingwithA'}
      is(last_response).ok?
      expect(items) == extract_elements('.pane-item').size

      items = count_books([query % :name, value % "Z"])
      expect(items) > 0
      get quick_filters: {name: 'Starting with Z'}
      is(last_response).ok?
      expect(items) == extract_elements('.pane-item').size
    end

    Testing 'cmp passed per filter' do
      a = %w[
        r 
        r,g
        g
        g,r
      ]
      1.upto(50) do
        app.model.create(:colors => a[rand(a.size)])
      end

      items = count_books( :colors => 'r')
      expect(items) > 0
      get quick_filters: {colors: 'Red'}
      is(last_response).ok?
      expect(items) == extract_elements('.pane-item').size

      query, value = query_map[:like_]
      items = count_books( [query % :colors, value % "g"])
      expect(items) > 0
      get quick_filters: {colors: 'GreenFirst'}
      is(last_response).ok?
      expect(items) == extract_elements('.pane-item').size
    end
  end

  class LikeApp < E
    include Rear
    model Book
    filter :name
    filter :about, cmp: :unlike
  end

  Spec.new LikeApp do
    
    query_map = RearConstants::FILTERS__QUERY_MAP.call(app.orm)

    (items = %w[abc123 abc456 abc789 foo bar]).each do |val|
      app.model.create :name => val, :about => val
    end

    Ensure 'all items displayed without filters' do
      get
      is(last_response).ok?
      elements = extract_elements
      items.each do |name|
        expect(elements).any? {|c| c.text == name}
      end
    end

    Testing :like do
      query, value = query_map[:like]
      items = count_books [query % :name, value % 'abc']
      expect(items) > 0
      get filters: {name: {like: 'abc'}}
      is(last_response).ok?
      elements = extract_elements('.pane-item')
      expect(elements.size) == items
    end

    Testing :unlike do
      query, value = query_map[:unlike]
      items = count_books [query % :about, value % 'abc']
      get filters: {about: {unlike: 'abc'}}
      is(last_response).ok?
      elements = extract_elements('.pane-item')
      expect(elements.size) == items
    end
  end

  class EqlApp < E
    include Rear
    model Book
    filter :name, cmp: :eql
  end

  Spec.new EqlApp do

    1.upto(10) { app.model.create name: random_string }
    item, item_id = new_book()

    get
    is(last_response).ok?
    expect(extract_elements('.pane-item').size) > 1

    get filters: {name: {eql: item.name}}
    is(last_response).ok?
    expect(extract_elements('.pane-item').size) == 1
  
  end

  class DecorativeFiltersApp < E
    include Rear
    model Book

    decorative_filter :letter, :select do
      ('A'..'Z').to_a
    end
    filter :name, :select, cmp: :like do
      filter?(:letter) ?
        NAMES.select {|n| n =~ /\A#{filter(:letter)}/} : {}
    end
  end

  Spec.new DecorativeFiltersApp do

    selector = '.selectable[name="filters[name][like]"]'

    get :html_filters
    filters = extract_elements(selector)
    expect(filters.size) == 1
    is(filters.first.children.select {|c| c.attr(:value).to_s.size > 0}).empty?

    %w[A D E].each do |letter|
      get :html_filters, filters: {letter: {decorative: letter}}
      is(last_response).ok?
      filters = extract_elements(selector)
      expect(filters.size) == 1
      children = filters.first.children.select {|c| c.attr(:value).to_s.size > 0}
      check(children.map {|c| c.text }.sort) ==
        NAMES.select {|n| n =~ /\A#{letter}/}.sort
    end
  end

  class InheritedType < E
    include Rear
    model Book
    filter :created_at
  end
  
  Spec.new InheritedType do
    get
    is(last_response).ok?
    elements = extract_elements('.search-query')
    expect(elements.select {|e|
      e.attr(:name) == 'filters[created_at][eql]'
    }.size) == 1
  end

end
