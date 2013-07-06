
By default **Rear** will add only the ability to filter by primary key.

To add more filters, use `filter`, `quick_filter` and `decorative_filter` methods.

The simplest case:

```ruby
class Photo
  include DataMapper::Resource
  # ...
end

Rear.register Photo do
  filter :name
end
```


## Filter Types

**Rear** supports following filter types:

    - :string/:text
    - :select
    - :radio
    - :checkbox
    - :date
    - :datetime
    - :time
    - :boolean

Filter type should be passed as second argument and should be a downcase symbol:

```ruby

  filter :created_at, :date

```

If no type given, **it will be inherited** from a column with same name, if any:

```ruby
class Page
  include DataMapper::Resource
  # ...
  property :created_at, Date
end

Rear.register Page do
  filter :created_at  # type inherited automatically
end
```

So, laziness is a virtue... sometimes...

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Comparison Functions

`:string/:text` filters will use `:like` comparison function by default,
so `filter :name` will generate a SQL like:

```
... WHERE name LIKE '%VALUE%' ...
```

`:checkbox` filters will use `:in` comparison function by default:

```
... WHERE column IN ('VALUE1', 'VALUE2') ...
```

If you use a custom "cmp" function with a `:checkbox` filter,
filter's column will be compared to each selected value:

```
... WHERE (column LIKE '%VALUE1%' OR column LIKE '%VALUE2%') ...
```

Filters of any other type will use equality for comparison function,
so a filter like `filter :created_at, :date` will generate an SQL like:

```
... WHERE created_at = 'VALUE' ...
```

To use a custom comparison function pass it via `:cmp` option:

```ruby

  filter :created_at, cmp: :like

```

Supported comparison functions:

    - :eql       # equal
    - :not       # not equal
    
    - :gt        # greater than
    - :gte       # greater than or equal
    - :lt        # less than
    - :lte       # less than or equal
    
    - :like      # uses left and right wildcards - "column LIKE '%VALUE%'"
    - :unlike    # - "column NOT LIKE '%VALUE%'"
    
    - :_like     # use only left wildcard, exact match for end of line - "column LIKE '%VALUE'"
    - :_unlike   # - "column NOT LIKE '%VALUE'"
    
    - :like_     # use only right wildcard, exact match for beginning of line - "column LIKE 'VALUE%'"
    - :unlike_   # - "column NOT LIKE 'VALUE%'"

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Optioned Filters

`:radio`, `:checkbox` and `:select` filters requires a block to run.

Block should return an Array or Hash.

Arrays used when stored keys are the same as displayed values:

```ruby

  filter :color do
    %w[Red Green Blue]
  end

```

If stored keys differs from displayed values, a `Hash` should be used:

```ruby

  filter :color do
    {'r' => 'Red', 'g' => 'Green', 'b' => 'Blue'}
  end

```

In example above 'r', 'g' and 'b' are db values and 'Red', 'Green', 'Blue' are displayed values.

If no block given, **Rear** will search for a column with same name and inherit options from there.

So if you have say a `:checkbox` column named `:colors` with defined options,
you only need to do `filter :colors`, without specifying type and options,
cause type and options will be inherited from earlier defined column:


```ruby

  input :colors, :checkbox do
    options 'Red', 'Green', 'Blue'
  end

  filter :colors # type and options inherited from :colors column

```

So, laziness is definitely a virtue...

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Decorative Filters

Sometimes you need to filter by some value that has too much options.

For ex. you want to filter pages by author and there are about 1000 authors in db.

Displaying all authors within a single dropdown filter is kinda cumbersome.

Decorative filters allow to narrow down the options displayed on other filters.

In example below authors will not be loaded until a letter selected:

```ruby
  
  decorative_filter :letter, :select do
    ('A'..'Z').to_a
  end

  filter :author_id, :select do
    if letter = filter?(:letter) # use the name of decorative filter with `filter?` method
      authors = {}
      model.all(name: /^#{letter}/).each |a|
        authors[a.id] = a.name
      end
      authors
    else
      {"" => "Select a letter please"}
    end
  end

```

A decorative filter will update filters every time new option selected and `filter?(:decorative_filter_name)` will return the selected option.

Worth to note that decorative filters will not actually query the db,
so you can name then as you want.

Also, decorative filters does not use/support custom comparison functions.

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Quick Filters


A.k.a Button Filters, allows to filter through items by simply clicking a button.

For ex. you need to quickly display active items.

A standard filter will require from user to select some value then click "Search" button.

Quick filters instead will create an "Active" button that will display only active items when clicked.

As per standard filters, when stored keys are the same as values, use an `Array`.

```ruby

  quick_filter :color, 'Red', 'Green', 'Blue'

```

This will create three grouped buttons that will display corresponding items on click.


And when keys are different, use a `Hash`:

```ruby

  quick_filter :color, 'r' => 'Red', 'g' => 'Green', 'b' => 'Blue'

```

This will create three buttons - Red, Green, Blue - that on click will display items with color equal to 'r', 'g', 'b' respectively.

And of course, as per standard filters, if you do not provide options, they will be inherited from a column with same name, if any:

```ruby
class Photo < ActiveRecord::Base
  # ...
end

Rear.register Photo do

  input :gamma, :checkbox do
    options "Red", "Green", "Blue"
  end
  
  quick_filter :gamma  # options are inherited from `:gamma` column
end
```

By default, quick filters will use equality for comparison function.

To use a custom comparison function, set it via `:cmp` option:

```ruby

  quick_filter :color, 'Red', 'Green', 'Blue', cmp: :like
  
```

**Hint** - if you need to filter through a column that has "cmp" as db value,
pass db value as string and cmp function as symbol:

```ruby
quick_filter :action, 'cmp' => 'Compare', 'snd' => 'Send', cmp: :like
```

It is also possible to use per filter comparison function:

```ruby
quick_filter :color, [:like, 'r'] => 'Red', 'g' => 'Green', 'b' => 'Blue'
# when Red clicked, LIKE comparison function will be used.
# on Green and Blue, equality will be used.
```

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Internal Filters

Used when you need fine-tuned control over displayed items.

Internal filters wont render any inputs, they will work under the hood.

`internal_filter` requires a block that should return a list of matching items.

**Example:** Display only articles newer than 2010:

```ruby
class Article
  include DataMapper::Resource

  property :id, Serial
  # ...
  property :created_at, Date, index: true
end

Rear.register Article do
  # ...

  internal_filter do
    Article.all(:created_at.gt => Date.new(2010))
  end
end
```

**Example:** Filter articles by category:

```ruby
class Article < ActiveRecord::Base
  belongs_to :category
end

Rear.register Article do
  
  # firstly lets render a decorative filter
  # that will render a list of categories to choose from
  decorative_filter :Category do
    Hash[ Category.all.map {|c| [c.id, c.name]} ]
  end

  # then we using internal_filter
  # to yield selected category and filter articles
  internal_filter do
    if category_id = filter?(:Category)
      Article.all(category_id: category_id.to_i)
    end
  end
end
```

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**
