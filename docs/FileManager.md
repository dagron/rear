
When you need a web file manager simply create a controller
and set path to managed folder via `fm_root`:

```ruby
class FileManager < E
  include Rear
  fm_root 'path/to/files/'
end
```

That's all. Now you have a *FileManager* menu entry. Click on it to manage your files.

## Text Editor

When you are dealing with files containing source code you need a specialized editor.

For now, Rear is offering support for [CKEditor](http://ckeditor.com) and [Ace](http://ace.ajax.org) editors.

Before using editors you'll have to install and load corresponding gems.

See [`rear-ckeditor`](https://github.com/espresso/rear-ckeditor) and
[`rear-ace`](https://github.com/espresso/rear-ace) for instructions.

After installed and loaded, simply use `fm_editor` to set desired editor:

```ruby
class FileManager < E
  include Rear
  fm_root 'path/to/files/'

  fm_editor :ace
  # or
  fm_editor :ckeditor
end
```


## Menu Label

If *FileManager* label is not suitable, use `label` to set custom menu label:

```ruby
class FileManager < E
  include Rear
  fm_root '../public/images'

  label :Images
end
```
now it will display *Images* in menu.

## Multiple

If you have multiple folders to manage, create a controller for each one.

Optionally you can put all file managers under same menu entry by using menu grouping:

```ruby
class Templates < E
  include Rear
  fm_root '../views/'
  
  menu_group :FileManager
end

class Images < E
  include Rear
  fm_root '../public/images'

  menu_group :FileManager
end
```
now you have *FileManager* menu entry that will reveal *Templates* and *Images* links on hover.

