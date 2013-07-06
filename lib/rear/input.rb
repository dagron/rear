class RearInput
  include RearConstants
  include RearUtils
  
  attr_reader :name, :string_name, :type
  attr_reader :dom_id, :css_class

  def initialize name, type = COLUMNS__DEFAULT_TYPE, attrs = {}, brand_new_item = nil, &proc
    @name, @string_name, @type = name, name.to_s, type
    @brand_new_item = brand_new_item
    @dom_id = ['Rear', 'Input', 'DOMIDFor', @string_name.capitalize.gsub(/\W/, ''), __id__].join
    @css_class = 'CSSClassFor' << @dom_id

    @pane_template = pane_template @type
    @pane_value    = proc do
      val = item[column.name]
      if val.is_a?(String)
        val.size > COLUMNS__PANE_MAX_LENGTH ?
          val[0..COLUMNS__PANE_MAX_LENGTH] + ' ...' : val
      else
        val
      end
    end

    @editor_template = editor_template @type
    @editor_value    = proc { item[column.name] }

    @active_options  = proc { item[column.name] }

    @html_attrs = Hash[[:*, :pane, :editor].map {|s| [s, {}]}]
    html_attrs(attrs)
    self.instance_exec(&proc) if proc
  end

  def name?
    return if disabled?
    return if readonly?
    multiple? || checkbox? ? '%s[]' % name : name.to_s
  end

  def label label = nil
    @label = label if label
    @label
  end

  def row row = nil
    @row = row.to_s if row
    @row 
  end

  def row?
    @row
  end

  def tab tab = nil
    @tab = tab.to_s if tab
    @tab 
  end

  def tab?
    @tab
  end

  # set HTML attributes to be used on current column on both pane and editor pages
  # @note will override any attrs set globally via `html_attrs` at class level
  def html_attrs attrs = {}
    set_html_attrs(attrs) if attrs.any?
    @html_attrs[:*] || {}
  end
  alias attrs html_attrs

  # set HTML attributes to be used on current column on pane pages
  # @note will override any attrs set globally via `pane_attrs` or `html_attrs` at class level
  def pane_attrs attrs = {}
    set_html_attrs(attrs, :pane) if attrs.any?
    pane_attrs? || html_attrs
  end

  def pane_attrs?
    (a = @html_attrs[:pane]) && a.any? && a
  end

  # set HTML attributes to be used on current column on editor pages
  # @note will override any attrs set globally via `editor_attrs` or `html_attrs` at class level
  def editor_attrs attrs = {}
    set_html_attrs(attrs, :editor) if attrs.any?
    editor_attrs? || html_attrs
  end

  def editor_attrs?
    (a = @html_attrs[:editor]) && a.any? && a
  end

  def pane_template template = nil, &proc
    caller.each {|l| puts l} if template == :integer
    if template
      @pane_template = 'pane/%s.slim' % template
    elsif template == false
      @pane_template = nil
    end
    @pane_template = proc if proc
    @pane_template
  end
  alias pane pane_template

  def pane_value &proc
    @pane_value = proc if proc
    @pane_value
  end

  def editor_template template = nil, &proc
    if template
      @editor_template = 'editor/%s.slim' % template
    elsif template == false
      @editor_template = nil
    end
    @editor_template = proc if proc
    @editor_template
  end
  alias editor editor_template

  def editor_value &proc
    @editor_value = proc if proc
    @editor_value
  end

  def value &proc
    pane_value   &proc
    editor_value &proc
  end

  # required on :radio, :checkbox and :select columns.
  # options provided as Array or Hash
  # use an Array when keys are the same as values.
  # use a Hash when keys are different from values.
  # if block given it should return an Array of selected keys or a single key.
  # if block not given, no options will be selected.
  #
  # @example use an Array. will send 'Orange' to ORM
  #
  #   column :fruit, :select do
  #     options('Apple', 'Orange', 'Peach') { 'Orange' }
  #   end
  #
  #
  # @example use a Hash. will send '2' to ORM
  #   
  #    column :fruit, :select do
  #      options(1 => 'Apple', 2 => 'Orange', 3 => 'Peach') { 2 }
  #    end
  #
  # @note when using :checkbox type or :select type with :multiple option,
  #       Espresso will send an Array of keys to your ORM.
  #       usually ORM will handle received array automatically,
  #       however, if you want to send a string rather than array,
  #       use `before` callback to coerce the array into string.
  #
  # @example  this example will send ['Orange', 'Peach'] Array
  #           which will be caught by `before :save` callback
  #           and coerced into string
  #
  #    before :save do
  #      params[:fruit] = params[:fruit].join(',')
  #    end
  #    column :fruit, :select, :multiple => true do
  #      options('Apple', 'Orange', 'Peach') { ['Orange', 'Peach'] }
  #    end
  #
  # @example will send ['2', '3'] Array to your ORM
  #   column :fruit, :checkbox do
  #     options(1 => 'Apple', 2 => 'Orange', 3 => 'Peach') { [2, 3] }
  #   end
  #
  def options *args, &proc
    return @options || {} if args.empty?
    @options = args.inject({}) do |f,c|
      c.is_a?(Hash) ? f.merge(c) : f.merge(c => c)
    end
    @active_options = proc if proc
  end

  def active_options
    @active_options
  end

  def optioned?
    select? || checkbox? || radio?
  end

  def pane?
    @pane_template
  end

  def editor?
    @editor_template
  end

  def readonly!
    @readonly = true
  end

  def readonly?
    return if @brand_new_item
    @readonly
  end

  def disable!
    @disabled = true
  end
  alias disabled! disable!

  def disabled?
    @disabled
  end

  def multiple!
    @multiple = true
  end

  def multiple?
    @multiple
  end

  def checkbox?
    type == :checkbox
  end

  def select?
    type == :select
  end

  def radio?
    type == :radio
  end

  def textual?
    type == :text || type == :rte
  end

  def boolean?
    type == :boolean
  end

  # when ordering by some column, "ORDER BY" will use only the selected column.
  # this column-specific setup allow to order returned items by multiple columns.
  #
  # # @example
  #   class News
  #     include DataMapper::Resource
  #
  #     property :id, Serial
  #     property :name, String
  #     property :date, Date
  #     property :status, Integer
  #   end
  #
  #   Rear.register News do
  #     input :date do
  #       order_by :date, :id
  #     end
  #   end
  #
  # this method are also useful when you need to sort items by a "decorative" column,
  # meant a column that does not exists in db but you need it on pane pages
  # to render more informative rows.
  # For ex. display category of each article when rendering articles
  #
  # # @example
  #   class Article
  #     include DataMapper::Resource
  #     # ...
  #
  #     belongs_to :category
  #   end
  #
  #   Rear.register do
  #     # defining a "decorative" column to display categories of each article
  #     input :Categories do
  #       pane { item.categories.map {|c| c.name}.join(', ') }
  #       # when Categories column clicked on pane page,
  #       # we want articles to be sorted by category id
  #       order_by :category_id
  #     end
  #   end
  #
  # @note do not pass ordering vector when setting costom `order_by` for columns.
  #       vector will be added automatically, so pass only column names.
  #       if vector passed, ordering will broke badly.
  #
  def order_by *columns
    @order_by = columns if columns.any?
    @order_by || [name]
  end

  def order_by?
    @order_by
  end

  # allow to define a list of snippets you need to insert into edited content.
  # relevant only on :ace / :ckeditor columns.
  def snippets *snippets, &proc
    snippets.any? && @snippets = snippets
    proc && @snippets = proc
    @snippets
  end

  # various opts for CKEditor
  #
  # @param [Hash] opts
  # @option opts :path
  #   physical path to folder containing images/videos to be picked up by file browser
  # @option opts :prefix
  #   file browser will build URL to file/video by extracting
  #   path(set via `:path` option) from full path to file.
  #   that's it, if path is "/foo/bar"
  #   and full path to file is "/foo/bar/baz/image.jpg",
  #   the URL used in browser will be  "/baz/image.jpg".
  #   `:prefix` option allow to define a string to be prepended to "/baz/image.jpg".
  # @option opts :lang
  #   localizing CKEditors
  def ckeditor opts = {}
    @ckeditor_opts = opts
  end
  def ckeditor_opts; @ckeditor_opts || {}; end

  private
  def set_html_attrs html_attrs, scope = :*
    html_attrs = Hash[@html_attrs[scope].merge(html_attrs)]

    html_attrs.each_key do |k|
      readonly! if k == :readonly
      disabled! if k == :disabled
      multiple! if k == :multiple
    end
    html_attrs.delete(:readonly) if @brand_new_item
    
    html_attrs.delete(:pane)   == false && pane(false)
    html_attrs.delete(:editor) == false && editor(false)

    unless @label = html_attrs.delete(:label)
      @label = name.to_s.gsub(/_/, ' ')
      @label.capitalize! unless name == :id
      @label << '?' if type == :boolean
    end
    @row = html_attrs.delete(:row)
    (tab = html_attrs.delete(:tab)) && (@tab = tab.to_s)
    
    @html_attrs[scope] = normalize_html_attrs(html_attrs)
  end

end
