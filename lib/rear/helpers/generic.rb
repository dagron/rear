module RearHelpers
  module InstanceMixin
    
    attr_reader   :items
    attr_accessor :item, :item_id, :column

    def item?
      @item_id && @item_id > 0
    end

    def orm
      @__rear__orm ||= RearORM.new(__rear__.model, __rear__.pkey)
    end

    def dom_id
      @__rear__dom_id ||= (params[:dom_id] || # params[:dom_id] are used by decorative filters
        (@reverse_assoc ? @reverse_assoc.dom_id : 'rear_element_%s' % self.__id__)).freeze
    end

    def model
      __rear__.model
    end

    def sequel?
      @@__rear__is_sequel ||= RearUtils.orm(model) == :sq
    end

    def pkey
      __rear__.pkey
    end

    def assocs *types
      return __rear__.assocs if types.empty?
      types.inject({}) do |assocs,type|
        assocs.merge(__rear__.assocs[type.to_sym] || {})
      end
    end

    def template_cache template
      ((@__rear__template_cache ||= {})[template] ||= {})[File.mtime(template)] ||= File.read(template)
    end

    # used for cosmetic compatibility between filters and columns.
    # columns block are executed inside Column instance,
    # and using `options` method to define options for :select/:radio/:checkbox columns.
    # filters of these types also uses a block and it is executed in controller's context.
    # so adding this method here will allow to use `options` method inside filter's block.
    #
    # @example
    #   filter :colors do
    #     options 'Red', 'Green', 'Blue'
    #   end
    #   # this is equivalent to 
    #   filter :colors do
    #     ['Red', 'Green', 'Blue']
    #   end
    #   # but looks cosmetically better cause uses same syntax as columns
    #
    def options *args
      args
    end

    def associated_model_controller model
      (@__rear__associated_model_controllers ||= {})[model] ||=
        RearUtils.associated_model_controller(model, :ensure_mounted)
    end

    def __rear__
      self.class
    end

    def readonly?
      self.class.readonly?
    end

    def shorten file, length = nil
      ext  = File.extname  file
      name = File.basename file, ext
      length ||= (name.scan(/[A-Z]/).size > 2 ? 8 : 10)
      name[0,length].strip << (name.size > length ? '..' : '') << ext
    end
  end
end
