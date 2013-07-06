module RearHelpers
  module ClassMixin

    def default_label
      @__rear__default_label ||= self.name.gsub(/\W/, '_').freeze
    end

    def menu_group?; @__rear__menu_group end
    def readonly?;   @__rear__readonly   end

    def orm
      @__rear__orm
    end

    def assocs
      @__rear__managed_assocs ||= (@__rear__assocs || {}).inject({}) do |map,(type,assocs)|
        map.merge type => assocs.reject {|assoc,*| ignored_assocs.include? assoc}
      end
    end

    # keeps a mix of "real" and "virtual" columns.
    # virtual columns refers to columns displayed on pane/editor pages 
    # but non existent in db
    def columns
      @__rear__columns ||= []
    end

    # keeps the list of columns that "physically" exists in db
    def real_columns
      @__rear__real_columns || []
    end

    def filters
      mounted? ? @__rear__filters || {} : @__rear__filters ||= {}
    end

    def quick_filters
      mounted? ? @__rear__quick_filters || {} : @__rear__quick_filters ||= {}
    end
    
    def internal_filters
      mounted? ? @__rear__internal_filters || [] : @__rear__internal_filters ||= []
    end
    
  end
end
