module RearHelpers
  module InstanceMixin

    def pager_linker page, attrs_and_opts = {}
      label = attrs_and_opts.delete(:label) || page
      url   = route(action, *action_params__array, pager_params(page))
      return link_to!(url, label, attrs_and_opts) unless xhr?
      
      onclick = "Rear.switch_page('#%s', '%s');" % [dom_id, url]
      link_to!(nil, label, attrs_and_opts.merge(onclick: onclick))
    end

    def pager_params page = nil, filters = nil
      page.is_a?(Hash) && (filters = page) && (page = nil)
      page ||= params[:page]
      {
                 page: page.to_s,
              filters: filters || pager_filters,
        quick_filters: opted_quick_filters,
                order: order_params
      }.reject {|k,v| v.nil? || v.empty?}
    end

    def pager_filters
      @__rear__pager_filters ||= filters.inject({}) do |map,(column, setups)|
        setups.each do |comparison_function, setup|
          (value = filter?(column, comparison_function)) &&
            (map[column] ||= {})[comparison_function] = value
        end
        map
      end
    end
    
  end
end
