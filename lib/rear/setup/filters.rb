module RearSetup
  
  # add a filter.
  #
  # by default a text filter will be rendered.
  # to define filters of another type, pass desired type as a Symbol via second argument.
  #
  # acceptable types:
  #   - :string/:text
  #   - :select
  #   - :radio
  #   - :checkbox
  #   - :date
  #   - :datetime
  #   - :time
  #   - :boolean
  # 
  # @note comparison function
  #       :text/:string filters will use :like comparison function by default:
  #       ... WHERE name LIKE '%VALUE%' ...
  #     
  #       :checkbox filters will use :in comparison function by default:
  #       ... WHERE column IN ('VALUE1', 'VALUE2') ...
  #       if you use a custom cmp function with a :checkbox filter,
  #       filter's column will be compared to each selected value:
  #       ... WHERE (column LIKE '%VALUE1%' OR column LIKE '%VALUE2%') ...
  #     
  #       any other types will use :eql comparison function by default:
  #       "... WHERE created_at = 'VALUE' ...
  #     
  #       to use a non-default comparison function, set it via :cmp option:
  #       `filter :name, :cmp => :eql`
  #
  #       available comparison functions:
  #         - :eql       # equal
  #         - :not       # not equal
  #         - :gt        # greater than
  #         - :gte       # greater than or equal
  #         - :lt        # less than
  #         - :lte       # less than or equal
  #         - :like      # - column LIKE '%VALUE%'
  #         - :unlike    # - column NOT LIKE '%VALUE%'
  #         - :_like     # match beginning of line - column LIKE 'VALUE%'
  #         - :_unlike   # - column NOT LIKE 'VALUE%'
  #         - :like_     # match end of line - column LIKE '%VALUE'
  #         - :unlike_   # - column NOT LIKE '%VALUE'
  #         - :_like_    # exact match - column LIKE 'VALUE'
  #         - :_unlike_  # - column NOT LIKE 'VALUE'
  #
  # @note if type not given,
  #       Rear will use the type of the column with same name, if any.
  #       if no column found, it will use :text
  #
  # @note :radio, :checkbox and :select filters requires a block to run.
  #       block should return an Array or a Hash.
  #       use an Array when stored keys are the same as displayed values.
  #       use a  Hash  when stored keys are different.
  #       Important! if no block given, Rear will search for a column
  #       with same name and type and inherit options from there.
  #       so if you have say a :checkbox column named :colors with defined options,
  #       you only need to do `filter :colors`, without specifying type and options.
  #       type and options will be inherited from earlier defined column.
  #
  # @example
  #
  #   class Page < ActiveRecord::Base
  #     # ...
  #     include Rear
  #     rear do
  #
  #       # text filter using :like comparison function
  #       filter :name
  # 
  #       # text filter using :eql comparison function
  #       filter :name, :cmp => :eql
  # 
  #       # date filter using :eql comparison function
  #       filter :created_at, :date
  # 
  #       # date filter using :gte comparison function
  #       filter :created_at, :date, :cmp => :gte
  # 
  #       # dropdown filter using :eql comparison function
  #       filter :color, :select do
  #         ['Red', 'Green', 'Blue']
  #       end
  #
  #       # dropdown filter using :like comparison function
  #       filter :color, :select, :cmp => :like do
  #         ['Red', 'Green', 'Blue']
  #       end
  #     end
  #   end
  #
  # @example :radio filter using Hash
  #
  #   rear do
  #     filter :color, :radio do
  #       {'r' => 'Red', 'g' => 'Green', 'b' => 'Blue'}
  #     end
  #   end
  #
  # @example inheriting type and options from a earlier defined column
  #
  #   rear do
  #     column :colors, :checkbox do
  #       options 'Red', 'Green', 'Blue'
  #     end
  #
  #     filter :colors # type and options inherited from :colors column
  #   end
  #
  # @param [Symbol] column
  # @param [Symbol] type
  # @param [Hash]   opts_and_or_html_attrs
  # @options opts_and_or_html_attrs :cmp comparison function
  # @options opts_and_or_html_attrs :label
  # @param [Proc] options block used on :select, :radio and :checkbox filters
  #               should return Array or Hash.
  #
  def filter column, type = nil, opts_and_or_html_attrs = {}, &proc
    
    opts = (opts_and_or_html_attrs||{}).dup
    type.is_a?(Hash) && (opts = type.dup) && (type = nil) && (opts_and_or_html_attrs = nil)
    matching_column = columns.find {|c| c && c.first == column}
    
    # if no type given, inheriting it from a column with same name, if any.
    type ||= (matching_column||[])[1]
    type = FILTERS__DEFAULT_TYPE unless FILTERS__HANDLED_TYPES.include?(type)

    # if filter is of :select, :radio or :checkbox type and no options block given,
    # inheriting it from a column with same name, if any.
    if proc.nil? && matching_column && matching_column[1] == type
      mci = RearInput.new(matching_column[0], type, &matching_column[3])
      mci.optioned? && proc = lambda { mci.options }
    end

    # using defaults if no comparison function given
    unless cmp = opts.delete(:cmp)
      cmp = case type
      when :text, :string
        :like
      when :checkbox
        :in
      else
        :eql
      end
    end

    unless label = opts.delete(:label)
      label = column.to_s
      label << '?' if type == :boolean
    end

    (filters[column.to_sym] ||= {})[cmp] = {
         template: 'filters/%s.slim' % type,
             type: type,
            label: label.freeze,
      decorative?: opts.delete(:decorative?),
            attrs: opts.freeze,
             proc: proc
    }.freeze
  end

  # sometimes you need to filter by some value that has too much options.
  # For ex. you want to filter pages by author and there are about 1000 authors in db.
  # displaying all authors within a single dropdown filter is kinda cumbersome.
  # we need to somehow narrow them down.
  # decorative filters allow to do this with easy.
  # in our case, we do not display the authors until a letter selected.
  # 
  # @example
  #   class Pages < E
  #     include Rear
  #     model PageModel
  #
  #     decorative_filter :letter, :select do
  #       ('A'..'Z').to_a
  #     end
  #
  #     filter :author_id, :select do
  #       if letter = filter?(:letter) # use here the name of decorative filter
  #         authors = {}
  #         AuthorModel.all(:name.like => "%#{letter}%").each |a|
  #           authors[a.id] = a.name
  #         end
  #         authors
  #       else
  #         {"" => "Select a letter please"}
  #       end
  #     end
  #   end
  #
  # @note
  #   decorative filters will not actually query the db, so you can name them as you want.
  #
  # @note
  #   decorative filters does not support custom comparison functions
  #
  def decorative_filter *args, &proc
    html_attrs = args.last.is_a?(Hash) ? Hash[args.pop] : {}
    setup = {decorative?: true, cmp: FILTERS__DECORATIVE_CMP}
    filter *args << html_attrs.merge(setup), &proc
  end

  # @example Array with default comparison function
  #   quick_filter :color, 'Red', 'Green', 'Blue'
  #   ... WHERE color = '[Red|Green|Blue]'
  #   
  # @example Array with custom comparison function
  #   quick_filter :color, 'Red', 'Green', 'Blue', :cmp => :like
  #   ... WHERE color LIKE '[Red|Green|Blue]'
  #   
  # @example Hash with default comparison function
  #   quick_filter :color, 'r' => 'Red', 'g' => 'Green', 'b' => 'Blue'
  #   ... WHERE color = '[r|g|b]'
  #
  # @example Hash with custom comparison function
  #   quick_filter :color, :cmp => :like, 'r' => 'Red', 'g' => 'Green', 'b' => 'Blue'
  #   ... WHERE color LIKE '%[r|g|b]%'
  #
  # @example Hash with comparison function defined per filter
  #   quick_filter :color, [:like, 'r'] => 'Red', 'g' => 'Green', 'b' => 'Blue'
  #   on Red
  #   ... WHERE color LIKE '%r%'
  #   on Green or Blue
  #   ... WHERE color = '[g|b]'
  #
  def quick_filter column, *args
    
    options = args.last.is_a?(Hash) ? args.pop : {}
    cmp = options.delete(:cmp) || :eql
    query_formats = FILTERS__QUERY_MAP.call(orm)
    if query_format = query_formats[cmp]
      options = Hash[options.map do |k,v|
        [
          v.to_s,
          k.is_a?(Array) ? [query_formats[k.first], k.last] : [query_format, k]
        ]
      end]

      # if options provided as arguments, adding them to options Hash
      args.each {|a| options[a.to_s] = [query_format, a.to_s] }

      # if no options given,
      # inheriting them from a column with same name, if any.
      if options.empty? && mc = columns.find {|c| c && c.first == column}
        mci = RearInput.new(mc[0], mc[1], &mc[3])
        mci.optioned? && mci.options.each_pair do |k,v|
          options[v.to_s] = [query_format, k]
        end
      end

      quick_filters[column.to_sym] = options
    end
  end

  
  # Used when you need fine-tuned control over displayed items.
  # Internal filters wont render any inputs, they will work under the hood.
  # `internal_filter` requires a block that should return a list of matching items.

  # @example Display only articles newer than 2010

  #   class Article
  #     include DataMapper::Resource

  #     property :id, Serial
  #     # ...
  #     property :created_at, Date, index: true
  #   end

  #   Rear.register Article do
  #     # ...

  #     internal_filter do
  #       Article.all(:created_at.gt => Date.new(2010))
  #     end
  #   end

  # @example Filter articles by category

  #   class Article < ActiveRecord::Base
  #     belongs_to :category
  #   end

  #   Rear.register Article do
      
  #     # firstly lets render a decorative filter
  #     # that will render a list of categories to choose from
  #     decorative_filter :Category do
  #       Hash[ Category.all.map {|c| [c.id, c.name]} ]
  #     end

  #     # then we using internal_filter
  #     # to yield selected category and filter articles
  #     internal_filter do
  #       if category_id = filter?(:Category)
  #         Article.all(category_id: category_id.to_i)
  #       end
  #     end
  #   end
  #
  def internal_filter &proc
    # instance_exec at runtime is expensive enough,
    # so compiling procs into methods at load time.
    chunks = [self.to_s, proc.__id__]
    name = ('__rear__%s__' % chunks.join('_').gsub(/\W/, '_')).to_sym
    define_method name, &proc
    private name
    internal_filters.push(name)
  end

end
