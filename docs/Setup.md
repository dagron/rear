
## Primary key

**Rear** will do its best to correctly detect the primary key of managed model.

In case it is failing to do so, you can set primary key manually by using `primary_key` method:

```ruby
  primary_key :ItemID
```

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**

## Ordering

**Rear** will fetch items in the order specified by your model or db.

It is also allow to set specific order by using `order_by` method:

`DataMapper`:

```ruby
  order_by :name, :id.desc
```

`ActiveRecord`:

```ruby
  order_by 'name, id DESC'
```

Also, on pane pages it is possible to order items by a specific column by clicking on it.
By default it will sort items in ascending order. To use descending order click on column one more time.

When sorting items this way, "ORDER BY" statement will use only selected column,
e.g. "ORDER BY name" or "ORDER BY date" etc.

To make Rear to sort by multiple columns when clicking on a specific one, set custom `order_by` for that column:

```ruby
class News
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :date, Date

end

Rear.register News do

  # making Rear to order by both name and date when name clicked
  input :name do
    order_by :name, :date
  end
end
```

**Important!** do not pass ordering vector when setting costom `order_by` for columns. Vector will be added automatically, so pass only column names.

**Example:** this will break ordering cause name specifies desc vector

```ruby
  input :name do
    order_by :name.desc, :date
  end
```



**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Items per page

By default **Rear** will display 10 items per page.

To have it displaying more or less, use `items_per_page` method or its alias - `ipp`:

```ruby
  items_per_page 50
```

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Menu Label

**Rear** will build a menu that will include all managed models.

By default, model name will be used as label:

```ruby
class PageModel < ActiveRecord::Base
  # ...
end

Rear.register PageModel
```

This will display "PageModel" in menu.

To have a custom label displayed, use `menu_label` method:

```ruby
Rear.register PageModel do
  menu_label :Pages
  # ...
end
```

Now it will display "Pages" in menu.

It is also possible to use `label` alias to set menu label.

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Menu Positioning

**Rear's** menu will display managed models in the the order they was defined.

To have a model displayed upper, set its position higher.

Or decrease position to have a model displayed lower.

```ruby
class City < ActiveRecord::Base
  # ...
end

class Country < ActiveRecord::Base
  # ...
end

class State < ActiveRecord::Base
  # ...
end

Rear.register City, Country, State
```

This will build a menu like `City | Country | State`.

```ruby
Rear.register City, Country, State do |model|
  menu_position({
    Country  => 1000,
    State    => 500,
    City     => 100,
  }[model])
end
```

This will build a menu like `Country | State | City`.

It is also possible to use `position` alias to set menu position.

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Menu Grouping

By default **Rear** will build a "flat" menu.

To have some models displayed under some group, use `menu_group` method:

```ruby
Rear.register City, Country, State do
  menu_group :Location
  # or
  under :Location  # `under` is an alias for `menu_group`
end
```

This will create "Location" group that will display "City", "Country" and "State" links on hover.

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## ReadOnly Mode

When you need to display a whole model in readonly mode, use `readonly!` method:

```ruby
class State < ActiveRecord::Base
  # ...
end

Rear.register State do
  readonly!
end
```

In readonly mode items can not be created/updated nor deleted.

Also all associations will be in readonly mode.


**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**

