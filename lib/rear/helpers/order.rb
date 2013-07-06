module RearHelpers
  module InstanceMixin

    # flip-flopping vectors, that's it, if current vector set to asc
    # this method will return desc, and vice-versa.
    # also it will return UI arrow direction - when vector is asc
    # arrow is down and arrow is up when vector is desc
    def sortable_vector column
      vector = ['asc', nil].include?(order_params[column.string_name]) ? 'desc' : 'asc'
      [vector, vector == 'asc' ? 'down' : 'up']
    end

    # checks whether ordering is happening by given column
    # and if it is, check whether a valid vector used
    def sortable_vector? column
      if vector = (params[:order] || {})[column.string_name]
        valid_sortable_vector? vector
      end
    end

    def valid_sortable_vector? vector
      vector if vector == 'asc' || vector == 'desc'
    end

    def order_params
      @__rear__order_params ||= pane_columns.inject({}) do |map,column|
        (vector = sortable_vector?(column)) ?
          map.update(column.string_name => vector) : map
      end.freeze
    end

    def order_params_to_sql
      order = []
      order_params.each_pair do |column_name, vector|
        if column_name == pkey.to_s
          column = RearInput.new(column_name)
        else
          next unless column = columns.find {|c| c.string_name == column_name}
        end
        case __rear__.orm
        when :dm
          column.order_by.each {|c| order << c.send(vector)}
        when :ar
          columns = column.order_by.map {|c| '%s %s' % [RearUtils.quote_ar_column(model, c), vector]}
          order  << columns.join(', ')
        when :sq
          column.order_by.each do |c| 
            # use Sequel::SQL::OrderedExpression
            sort_item = vector=='desc' ? Sequel.desc(c.to_sym) : Sequel.asc(c.to_sym)
            order << sort_item
          end
        end
      end
      order.any? ? order : nil
    end
  end
end
