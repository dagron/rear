

**Rear** will automatically detect and handle all columns defined by your model
and allow you to fine-tune them.

## Column Types

Following types will be handled automatically:

    - :string
    - :text
    - :date
    - :time
    - :datetime
    - :boolean

Following types should be set manually:

    - :rte - rich text editor, aka WYSIWYG editor
    - :radio
    - :checkbox
    - :select
    - :password


To define a column of specific type, use `input` method with column name as first argument and type as second argument:

```ruby
class Foo < ActiveRecord::Base
  # ...
end

Rear.register Foo do
  input :content, :ckeditor
end
```

Manually setting columns makes sense only when you need to use a custom type
or/and add some extra opts, like HTML attributes or a fine-tuning block.

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Columns Label

By default **Rear** will use capitalized column name as label for pane and editor pages.

To have a custom label, use `:label` option or `label` method inside block:

```ruby
  input :date, label: 'Select date please'
  # or
  input :date do
    label 'Select date please'
  end
```

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Radio/Checkbox/Select Columns

These types of columns requires a block to work properly.

Options can be provided via `options` method.

It accepts a `Hash` or `Array`.

When stored keys and displayed values are the same, use an `Array`:

```ruby
input :color, :select do
  options 'Red', 'Green', 'Blue'
end
```

When stored keys are different from displayed values, use a `Hash`:

```ruby
input :color, :radio do
  options 'r' => 'Red', 'g' => 'Green', 'b' => 'Blue'
end
```

Radio and single Select columns will send a `String` to your ORM.

Checkbox and multiple Select columns will send an `Array`.

If your ORM does not handle arrays automatically,
you'll have to use a **Rear** hook to convert sent `Array` into a `String`:


```ruby
input :color, :checkbox do
  options 'r' => 'Red', 'g' => 'Green', 'b' => 'Blue'
end

on_save do
  params[:color] = params[:color].join(',')
end
```

Now if say "Red" and "Green" options checked, an "r,g" `String` will be sent to ORM.

However, now no options will be automatically checked on editor page.

That's because **Rear** loads "r,g" `String` from db and does not know how to correctly convert it into array.

We have to pass a block to `options` method that will have access to `item` object and should return an array:

```ruby
input :color, :checkbox do
  options 'r' => 'Red', 'g' => 'Green', 'b' => 'Blue' do
    item.color.split(',')
  end
end

on_save do
  params[:color] = params[:color].join(',')
end
```

This way we dumping data via a hook and loading it via a block.


**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Rich Text Editors

When you are dealing with columns containing source code you need a specialized editor.

For now, Rear is offering support for [CKEditor](http://ckeditor.com) and [Ace](http://ace.ajax.org) editors.

Before using editors you'll have to install and load corresponding gems.

See [`el-ckeditor`](https://github.com/espresso/el-ckeditor) and
[`el-ace`](https://github.com/espresso/el-ace) for details.

Editing HTML using CKEditor:

```ruby
class MyModel < ActiveRecord::Base
  # ...
end

Rear.register MyModel do
  input :content, :ckeditor
end
```

### CKEditor File Browser

If you need a file browser to pick up images/movies from, set path to files via `ckeditor` method:

```ruby
input :content, :ckeditor do
  ckeditor path: '../public/images'
end
```

When setting image's URL, **Rear** will remove `:path` from image's physical path,
so if `:path` was set to */foo/bar*, */foo/bar/baz/image.jpg* will become */baz/image.jpg* in browser.

If your web server is looking for images in */anything/baz/image.jpg*,
use `:prefix` option to prepend */anything* to image's URL:

```ruby
input :content, :ckeditor do
  ckeditor path: '../public/images', prefix: '/anything'
end
```

### CKEditor Localization

It is possible to localize CKEditor via `lang` option:

```ruby
input :content, :ckeditor do
  ckeditor lang: :de
end
```

### Ace Editor

To make use of Ace editor, set column type to `:ace`:

```ruby
Rear.register ModelName do
  input :content, :ace
end
```

### Snippets

If you have a list of snippets you need to insert into edited content, pass them into editor via `snippets` method. 

Both CKEditor and Ace editors will detect passed snippets and enable a dialog allowing you to insert them.

Snippets ca be passed as multiple arguments, as a single array argument or as a proc that returns an array:

```ruby
input :content, :ckeditor do # or :ace
  snippets '{{ "top-menu" }}', '{{ "left-menu" }}'
  # or
  snippets ['{{ "top-menu" }}', '{{ "left-menu" }}']
  # or
  snippets do
    ['{{ "top-menu" }}', '{{ "left-menu" }}']
  end
end
```

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Readonly/Disabled Columns

Sometimes you need some column to be displayed on editor in readonly/disabled mode.

This can be achieved by using options or block:

Using options:

```ruby
input :visits, readonly: true
# or
input :visits, disabled: true
```

Using block with `readonly!` and `disabled!` methods:

```ruby
input :visits do
  readonly!
end
# or
input :visits do
  disabled!
end
```

In both cases readonly/disabled attributes will be added to HTML tag.

Worth to note that readonly status is *effective only on existing items*.

When creating new items all columns will be editable.

Disabled columns instead will always be disabled, regardless item is new or existing.

If you need to totally exclude some column from editor, set `editor` option to false:

```ruby
input :visits, editor: false
# or
input :visits do
  editor false
end
```

If you need it also excluded from pane pages, set `pane` option to false:

```ruby
input :visits, editor: false, pane: false
# or
input :visits do
  editor false
  pane   false
end
```

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Organizing Columns by Rows

By default a separate row will be used for each column.

To render N columns on same row, use `:row` option or `row` method inside block:

```ruby
input :meta_title,       row: :Meta
input :meta_discription, row: :Meta
input :meta_keywords,    row: :Meta

# or

row :Meta do
  input :meta_title   
  input :meta_discription
  input :meta_keywords
end

# or use a nameless row

row do
  input :active
  input :published
  input :archived
end
```

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Organizing Columns by Tabs

By default all columns will be contained in one tab.

If you need a separate tab for several columns, use `tab` method with a block:

```ruby
tab :Meta do
  input :meta_title   
  input :meta_discription
  input :meta_keywords
end
```

It is also possible to pass tab as option:

```ruby
input :meta_title,       tab: :Meta
input :meta_discription, tab: :Meta
input :meta_keywords,    tab: :Meta
```

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**



## HTML Attributes

When you need to provide extra attributes to column's HTML tag,
pass them as options or use `html_attrs` method inside block:

```ruby
input :short_text, style: "height: 400px;"

# or

input :short_text do
  html_attrs style: "height: 400px;"
end
```

When passing attrs as options or via `html_attrs` method, they will be used on both pane and editor pages.

Use `pane_attrs` to set attrs used only on pane pages and `editor_attrs` to set attrs used only on editor pages respectively.

**Please Note** that on pane pages attrs will be added to the div element containing column value.
On editor pages instead, attrs will be added to the input element, being it text, textarea, select, radio etc.

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Loading Data

By default the column value will be displayed as extracted from db.

If you need to pre-process data before displaying it, use `value` method with a block.

```ruby
input :created_at do
  value { item.created_at.strftime('%d %m, %Y') }
end
```

`value` method will set loader for both pane and editor pages.

To set loader for either of them use `pane_value` or `editor_value` methods:

```ruby
input :created_at do
  pane_value { item.created_at.strftime('%d %m, %Y') }
end
```

**`value` wont work on :radio/:checkbox/:select columns**,
which uses a block passed to `options` method to load data.


**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**


## Hiding Columns

There are two pages where **Rear** will display columns - **Pane** pages and **Editor** pages.

Pane pages, aka summary pages, will display all available items,
with a paginator and filters.

Editor pages, aka CRUD pages, will allow to Create, Edit, Delete a specific item.

By default any column will be displayed on any page.

To hide it on some page, set `:pane` / `:editor` option to false:

```ruby
input :content, pane: false   # long text, do not display on pane pages
input :visits,  editor: false # stat can not be edited
```

Also a block can be used to setup columns.

In this case `pane` / `editor` methods are used with first argument set to false:

```ruby
input :content do
  pane false
end
input :visits do
  editor false
end
```

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**

## Resetting Columns

In case you are not satisfied with columns automatically added by **Rear**, reset them and start over with your own.

Columns can be reseted by using `reset_columns!` method:

```ruby
reset_columns!
```

**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**

