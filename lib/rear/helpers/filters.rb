module RearHelpers
  module InstanceMixin

    def filters
      __rear__.filters
    end

    def quick_filters
      __rear__.quick_filters
    end

    def opted_quick_filters
      @__rear__opted_quick_filters ||= begin
        given_filters = params[:quick_filters] || {}
        quick_filters.inject({}) do |map,(column,*)|
          (v = given_filters[column.to_s]) && v.size > 0 ? map.merge(column => v) : map
        end
      end
    end

    def quick_filter? column
      opted_quick_filters[column]
    end

    # turn
    # {'date' => {'gte' => 'foo', 'lte' => 'bar'}}
    # into
    # {
    #   :date => {
    #             :gte => ['foo', ['%s >= ?', '%s'] ],
    #             :lte => ['bar', ['%s <= ?', '%s'] ],
    #            }
    # }
    def opted_filters
      @__rear__opted_filters ||= (params[:filters]||{}).inject({}) do |map,s|
        (column = s.first) && (filter = filters[(column = column.to_sym)]).is_a?(Hash) &&
          (setup = s.last).is_a?(Hash) && setup.each_pair do |cmp,v|
            v && v.size > 0 && (query_formats = filters_query_map[(cmp=cmp.to_sym)]) &&
              (filter_setup = filter[cmp]) && (map[column] ||= {})[cmp] = [
                v, # do not typecast to Fixnum cause this will break Hash to query_string conversion
                query_formats,
                filter_setup,
              ]
          end
        map
      end
    end

    def filters_query_map
      @@__rear__filters__query_map ||= FILTERS__QUERY_MAP.call(__rear__.orm)
    end

    def filter name, comparison_function = FILTERS__DECORATIVE_CMP
      ((opted_filters[name] || {})[comparison_function] || []).first
    end
    alias filter? filter
    alias decorative_filter? filter

    def filters_to_sql
      conditions, sql_chunks, values = {}, [], []
      
      quick_filters.each_pair do |column,filters|
        next unless label = opted_quick_filters[column]
        filters.each_pair do |filter,(query_formats,value)|
          next unless label == filter
          sql_chunks  << query_formats.first % RearUtils.quote_column(model, column)
          values << ([TrueClass, FalseClass, Regexp].include?(value.class) ? value : query_formats.last % value)
        end
      end

      opted_filters.each_pair do |column, setups|
        setups.each_pair do |cmp, (value, query_formats, filter_setup)|
          next if filter_setup[:decorative?]
          
          sql_chunk = query_formats.first % RearUtils.quote_column(model, column)
          custom_sql_chunk  = nil

          if filter_setup[:type] == :boolean && FILTERS__STR_TO_BOOLEAN.has_key?(value)
            values << FILTERS__STR_TO_BOOLEAN[value]
          else
            case cmp
            when :in
              values << value
            when :csl # comma separated list
              values << value.to_s.split(',')
            else
              if value.is_a?(Array)
                custom_sql_chunk = []
                value.each do |v|
                  custom_sql_chunk << sql_chunk
                  values << query_formats.last % v
                end
                custom_sql_chunk = '(' + custom_sql_chunk.join(' OR ') + ')'
              else
                values << query_formats.last % value
              end
            end
          end
          sql_chunks << (custom_sql_chunk || sql_chunk)
        end
      end

      __rear__.internal_filters.each do |m|
        next unless items = self.send(m)
        sql_chunks << filters_query_map[:in].first % pkey
        values     << items.map {|i| i[pkey]}
      end

      sql_chunks.any? ?
        conditions.merge(conditions: [sql_chunks.join(' AND '), *values]) :
        conditions
    end

    def render_filters
      html = assets_mapper(route(:assets), suffix: '-rear').js_tag('xhr')
      main_filters = filters.inject(html) do |html,(column,setups)|
        setups.each_pair do |comparison_function, setup|
          context = {
              name: 'filters[%s][%s]' % [column, comparison_function],
            column: column,
             value: filter(column, comparison_function),
             setup: setup,
             attrs: Hash[setup[:attrs]]
          }
          template = template_cache(path_to_rear_templates(setup[:template]))
          html << render_slim_p(context) { template }
        end
        html << '&nbsp;'
      end
    end

    def filter_setup_to_options(setup)
      options = setup[:proc] ? self.instance_exec(&setup[:proc]) : {}
      if options.is_a?(Array)
        options.flatten!
        options = Hash[options.zip(options)]
      end
      return options if options.is_a?(Hash)
      options.nil? || warn("
      %s#%s filter requires a block that returns a Hash or Array
      " % [self.class, setup[:label]])
      {}
    end
    
  end
end
