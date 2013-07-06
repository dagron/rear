
**Rear** can run in standalone mode or can be integrated/mounted into any `Espresso` application.

## Running a standalone application:

`$ cat config.ru`
```ruby
require 'rear'

# model
class Page < ActiveRecord::Base
  # ...
end

# controller
Rear.register Page do
  # some setups, if any
end

run Rear
```

Then `$ rackup -s ServerName -p PortNumber` to start it.


## Integrating Rear into existing Espresso application:

```ruby
# models
class Page < ActiveRecord::Base
  # ...
end

# backend controllers
Rear.register Page

# frontend controllers
module Frontend
  class Pages < E
    map '/'
    # ...
  end
end

# Espresso application
app = E.new

# mounting frontend controllers into root URL
app.mount Frontend, '/'

# mounting backend controllers into /admin URL
app.mount Rear.controllers, '/admin'

# starting app
app.run :server => ServerName, :port => PortNumber
```

So basically mount **Rear.controllers** wherever you need.


**[ [contents &uarr;](https://github.com/espresso/rear#tutorial) ]**

