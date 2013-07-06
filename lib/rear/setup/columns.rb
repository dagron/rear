module RearSetup
  
  # add new column or override automatically added one
  #
  # @param [Symbol] name
  # @param [Symbol] type  one of [:string, :text, :date, :time, :datetime, :boolean]
  #                       default: :string
  # @param [Hash]   opts_and_or_html_attrs
  # @option opts_and_or_html_attrs :pane
  #   when set to false the column wont be displayed on pane pages
  # @option opts_and_or_html_attrs :editor
  #   when set to false the column wont be displayed on editor pages
  # @option opts_and_or_html_attrs :label
  # @option opts_and_or_html_attrs :readonly
  # @option opts_and_or_html_attrs :disabled
  # @option opts_and_or_html_attrs :multiple
  # @option opts_and_or_html_attrs any attributes to be added to HTML tag
  #
  # @example
  #   input :name
  #   # => <input type="text" value="...">
  #
  # @example
  #   input :name, :style => "width: 100%;"
  #   # => <input style="width: 100%;" type="text" ...>
  #
  # @example
  #   input :name, :text, :cols => 40
  #   # => <textarea cols="40" ...>...</textarea>
  #
  # @example display author name only on pane pages
  #   input(:author_id) { disable :editor }
  # 
  # @example Ace Editor
  #   input :content, :ace
  #
  # @example CKEditor
  #   input :content, :ckeditor
  #
  def input name, type = nil, opts_and_or_html_attrs = {}, &proc

    type.is_a?(Hash) && (opts_and_or_html_attrs = type) && (type = nil)
    opts_and_or_html_attrs[:row] = opts_and_or_html_attrs[:row] ?
      opts_and_or_html_attrs[:row].to_s : @__rear__row
    opts_and_or_html_attrs[:tab] = opts_and_or_html_attrs[:tab] ?
      opts_and_or_html_attrs[:tab].to_s : @__rear__tab

    existing_column = nil
    columns.each_with_index {|c,i| c && c.first == name && existing_column = [c,i]}
    column = existing_column ? Array.new(existing_column.first) : []

    column[0] = name
    column[1] = type ? type.to_s.downcase.to_sym : column[1] || COLUMNS__DEFAULT_TYPE
    column[2] = (column[2]||{}).merge(opts_and_or_html_attrs).freeze
    column[3] = proc
    column.freeze

    existing_column ?
      columns[existing_column.last] = column :
      columns << column
  end

  # reset any automatically(or manually) added columns
  def reset_columns!
    @__rear__columns = {}
  end

  # display multiple columns in a row(on editor)
  #
  # @example using a block
  #
  #   row :Location do
  #     column :country
  #     column :state
  #     column :city
  #   end
  #
  # @example without a block
  #
  #   column :country, row: :Location
  #   column :state,   row: :Location
  #   column :city,    row: :Location
  #
  def row label = nil, &proc
    # explicit labels will be strings and implicit ones will be numbers
    # as a way to distinguish them when rendering templates
    @__rear__row = label ? label.to_s : (Time.now.to_f + rand)
    self.instance_exec(&proc) if proc
    @__rear__row = nil
  end

  # by default all columns will be contained in main tab.
  # this method allow to create a new tab and move some columns into it.
  #
  # @example using a block
  #
  #   tab :Meta do
  #     column :meta_title
  #     column :meta_description
  #     column :meta_keywords
  #   end
  #
  # @example without a block
  #
  #   column :meta_title,       tab: :Meta
  #   column :meta_description, tab: :Meta
  #   column :meta_keywords,    tab: :Meta
  #
  # @param [String] label
  # @param [Proc] &proc
  #
  def tab label, &proc
    @__rear__tab = label
    self.instance_exec(&proc) if proc
    @__rear__tab = nil
  end

  # set HTML attributes to be used on all columns on both pane and editor pages
  def html_attrs attrs = {}
    @__rear__html_attrs = attrs if attrs.any? && @__rear__html_attrs.nil?
    @__rear__html_attrs || {}
  end

  # set HTML attributes to be used on all columns only on pane pages.
  # @note will override any attrs set via `html_attrs`
  def pane_attrs attrs = {}
    @__rear__pane_attrs = attrs if attrs.any? && @__rear__pane_attrs.nil?
    @__rear__pane_attrs || html_attrs
  end

  # set HTML attributes to be used on all columns only on editor pages.
  # @note will override any attrs set via `html_attrs`
  def editor_attrs attrs = {}
    @__rear__editor_attrs = attrs if attrs.any? && @__rear__editor_attrs.nil?
    @__rear__editor_attrs || html_attrs
  end
end
