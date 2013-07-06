module RearHelpers
  module ClassMixin
    include RearConstants
  end

  module InstanceMixin
    include RearConstants
  end
end

require 'rear/helpers/class'
require 'rear/helpers/columns'
require 'rear/helpers/filters'
require 'rear/helpers/generic'
require 'rear/helpers/order'
require 'rear/helpers/pager'
require 'rear/helpers/render'
require 'rear/helpers/file_browser'
