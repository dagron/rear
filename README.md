
# Rear

<a href="https://travis-ci.org/espresso/rear">
<img align="right" src="https://travis-ci.org/espresso/rear.png"></a>

### ORM-agnostic CRUDifier for Espresso Framework ([DEMO](http://rear.rbho.me/))

## Highlights

  - `ActiveRecord`, `DataMapper`, `Sequel` support
  - Associations of any type supported
  - Fully dynamic interface, no scaffolding
  - Custom templates when needed
  - Minimal dependencies - `Espresso` and `Slim`
  - Tested on all 1.9+ Rubies


## Quick Start

```ruby
require 'rear' # or add "gem 'rear'" to Gemfile

# model
class Page < ActiveRecord::Base
  # ...
end

# controller
Rear.register Page do
  # setups goes here, if any
end
```

**Run**

```ruby
Rear.run

# or
E.new do
  mount Rear.controllers
  run
end
```

## Tutorial

### [Setup](https://github.com/espresso/rear/blob/master/docs/Setup.md)


[Primary key](https://github.com/espresso/rear/blob/master/docs/Setup.md#primary-key) |
[Ordering](https://github.com/espresso/rear/blob/master/docs/Setup.md#ordering) |
[Items per page](https://github.com/espresso/rear/blob/master/docs/Setup.md#items-per-page) |
[Menu Label](https://github.com/espresso/rear/blob/master/docs/Setup.md#menu-label) |
[Menu Positioning](https://github.com/espresso/rear/blob/master/docs/Setup.md#menu-positioning) |
[Menu Grouping](https://github.com/espresso/rear/blob/master/docs/Setup.md#menu-grouping) |
[ReadOnly Mode](https://github.com/espresso/rear/blob/master/docs/Setup.md#readonly-mode)


### [Columns](https://github.com/espresso/rear/blob/master/docs/Columns.md)

[Type](https://github.com/espresso/rear/blob/master/docs/Columns.md#column-types) |
[Label](https://github.com/espresso/rear/blob/master/docs/Columns.md#columns-label) |
[Radio/Checkbox/Select](https://github.com/espresso/rear/blob/master/docs/Columns.md#radiocheckboxselect-columns) |
[Rich Text Editors](https://github.com/espresso/rear/blob/master/docs/Columns.md#rich-text-editors) |
[Readonly/Disabled](https://github.com/espresso/rear/blob/master/docs/Columns.md#readonlydisabled-columns) |
[Rows](https://github.com/espresso/rear/blob/master/docs/Columns.md#organizing-columns-by-rows) |
[Tabs](https://github.com/espresso/rear/blob/master/docs/Columns.md#organizing-columns-by-tabs) |
[HTML Attributes](https://github.com/espresso/rear/blob/master/docs/Columns.md#html-attributes) |
[Loading Data](https://github.com/espresso/rear/blob/master/docs/Columns.md#loading-data)<br>
[Hiding Columns](https://github.com/espresso/rear/blob/master/docs/Columns.md#hiding-columns) |
[Resetting Columns](https://github.com/espresso/rear/blob/master/docs/Columns.md#resetting-columns)


### [Associations](https://github.com/espresso/rear/blob/master/docs/Assocs.md)

[Columns List](https://github.com/espresso/rear/blob/master/docs/Assocs.md#columns-list) |
[Ignored Associations](https://github.com/espresso/rear/blob/master/docs/Assocs.md#ignored-associations) |
[Readonly Associations](https://github.com/espresso/rear/blob/master/docs/Assocs.md#readonly-associations)


### [Filters](https://github.com/espresso/rear/blob/master/docs/Filters.md)

[Type](https://github.com/espresso/rear/blob/master/docs/Filters.md#filter-types) |
[Comparison Functions](https://github.com/espresso/rear/blob/master/docs/Filters.md#comparison-functions) |
[Optioned Filters](https://github.com/espresso/rear/blob/master/docs/Filters.md#optioned-filters) |
[Decorative Filters](https://github.com/espresso/rear/blob/master/docs/Filters.md#decorative-filters) |
[Quick Filters](https://github.com/espresso/rear/blob/master/docs/Filters.md#quick-filters)

### More

[FileManager](https://github.com/espresso/rear/blob/master/docs/FileManager.md) |
[Deploy](https://github.com/espresso/rear/blob/master/docs/Deploy.md) |
[Demo](http://rear.rbho.me/)

## Contributing

  - Fork Rear repository
  - Make your changes
  - Submit a pull request

### Author - [Walter Smith](https://github.com/waltee).  License - [MIT](https://github.com/espresso/rear/blob/master/LICENSE).
