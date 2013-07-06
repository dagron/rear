
**Rear** will automatically detect and handle all associations defined inside your models.

See [Ignored Associations](https://github.com/espresso/rear/blob/master/docs/Assocs.md#ignored-associations) if you need to disable some of them(s).


## Columns List

When rendering some model as association of other model, all columns of current model will be displayed, just like on pane pages.

That's reasonable enough, though sometimes redundant,
cause if current model has about 10 columns, you definitely do not need them all displayed in association pane.

To limit "remotely" displayed columns, use `assoc_columns`:

```ruby
class Book < ActiveRecord::Base
  has_one :author
end

class Author < ActiveRecord::Base

  # supposing you have :first_name, :last_name, :about and :resume columns here.
end

Rear.register Book, Author do |model|

  # display only :first_name and :last_name when authors shown on Book editor
  assoc_columns :first_name, :last_name if model == Author
end
```

In example above, when authors are displayed on book's editor pages, only `:first_name` and `:last_name` columns will be displayed, cause we really do not need `:about`/`:resume` columns to select an author for current book.

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Ignored Associations

To ignore some association, use `ignore_assoc :assoc_name`:

```ruby
class Page < ActiveRecord::Base
  belongs_to :author
end

Rear.register Page do
  ignore_assoc :author
end
```

To mark multiple associations as ignored, use: `ignored_assocs :a1, :a2, :etc`:

```ruby
class Page < ActiveRecord::Base
  belongs_to :author
  has_many   :tags
end

Rear.register Page do
  ignored_assocs :author, :tags
end
```

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Readonly Associations

It is also possible to display associations in readonly mode by using `readonly_assoc :assoc_name`:

```ruby
class Page < ActiveRecord::Base
  belongs_to :author
end

Rear.register Page do
  readonly_assoc :author
end
```

To mark multiple associations as readonly, use: `readonly_assocs :a1, :a2, :etc`:

```ruby
class Page < ActiveRecord::Base
  belongs_to :author
  has_many   :tags
end

Rear.register Page do
  readonly_assocs :author, :tags
end
```


Please note that readonly mode are effective only on existing items.<br>
When creating new items all associations are editable.


**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**
