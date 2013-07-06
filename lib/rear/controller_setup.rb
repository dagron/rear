class RearControllerSetup
  include RearConstants

  class << self
    def init(*args, &proc)
      new.init(*args, &proc)
    end

    def crudify(*args, &proc)
      new.crudify(*args, &proc)
    end
  end

  def init ctrl
    (@ctrl = ctrl).class_exec do
      extend  RearSetup
      extend  RearHelpers::ClassMixin
      include RearConstants
      include RearHelpers::InstanceMixin
      import  RearActions

      include EL::Ace if defined?(EL::Ace)
      include EL::CKE if defined?(EL::CKE)

      reject_automount!
      EUtils.register_extra_engines!
    end

    define_setup_methods
    define_error_handlers
    setup_file_browser
  end

  def crudify ctrl, model, opts, &proc
    (@ctrl = ctrl).class_exec do
      @__rear__orm = RearUtils.orm(model)
      @__rear__assocs = RearUtils.extract_assocs(model)
      @__rear__real_columns, @__rear__pkey = RearUtils.extract_columns(model)
      @__rear__real_columns.each do |c|
        input(*c) unless @__rear__assocs[:belongs_to].any? {|a,s|
          s[:belongs_to_keys][:source] == c.first
        }
      end
    end

    setup_crudifier(opts, &proc)
    define_association_hooks
    define_pane_hooks
    define_editor_hooks
    define_default_filters
  end

  def setup_crudifier opts, &proc
    @ctrl.class_exec do

      # use :destroy! on DataMapper
      opts[:delete] ||= :destroy! if orm == :dm

      # asking Espresso to define CRUD actions
      crudify(model, :crud, opts, &proc)

      alias_before :post_crud,   :create, :save
      alias_before :put_crud,    :update, :save
      alias_before :delete_crud, :destroy

      before :create, :update, :destroy do
        halt(400, '%s is in readonly mode' % model) if readonly?
      end
    end
  end

  def define_default_filters
    @ctrl.class_exec do
      # built-in filter for all controllers. it will search by primary key
      filter(pkey, cmp: :csl, class: 'input-small search-query')
    end
  end

  def define_setup_methods
    @ctrl.class_exec do

      # allow to set path to custom templates.
      # to use custom templates install them via "$ rear i:t PATH"
      # and use `rear_templates PATH` when mounting Rear controllers.
      #
      # @example
      #   # install templates in views/ folder
      #   $ rear i:t views/
      #
      #   # set path to custom templates when mounting Rear controllers
      #   E.new do
      #     mount Rear.controllers, '/admin' do
      #       rear_templates 'views/rear/'
      #     end
      #   end
      #
      def rear_templates path
        return @__rear__templates_fullpath = path.to_s if path =~ /\A(\w\:)?\// && @__rear__templates_fullpath.nil?
        @__rear__templates_path = path.to_s if @__rear__templates_path.nil?
      end
      define_setup_method :rear_templates

      # similar to `rear_templates` except it sets path to custom assets
      def rear_assets path
        return @__rear__assets_fullpath = path.to_s if path =~ /\A(\w\:)?\// && @__rear__assets_fullpath.nil?
        @__rear__assets_path = path.to_s if @__rear__assets_path.nil?
      end
      define_setup_method :rear_assets
    end
  end

  def define_error_handlers
    @ctrl.class_exec do
      error 500 do |e|
        error = if e.respond_to?(:backtrace)
          e.backtrace.inject([e.message]) {|bt,l| bt << l}
        elsif e.is_a?(Array)
          e
        else
          [e.to_s]
        end
        out = rq.xhr? ? error*"\n" : reander_l(:layout) {reander_p :error, error: error}
        halt 500, out
      end
    end
  end

  def define_association_hooks
    @ctrl.class_exec do
      # all communications between associated models happens through primary keys.
      # it does not matter what keys models using to associate one to each other,
      # Rear will always use pkeys to display/update associated objects.
      # this is achieved by using ORM setters for associated objects,
      # like `state=` on `belongs_to :state` assocs
      # or `cities<<` on `has_many :cities` etc.
      # so it will basically fetch remote objects by pkey and feed them to that setters.
      #
      # hooks order is important. this one should always go first
      before /reverse_assoc/ do
        ctrl     = action_params[:source_ctrl].split('::').inject(Object) {|f,c| f.const_get(c)}
        assoc    = ctrl.assocs[action_params[:assoc_type].to_sym][action_params[:assoc_name].to_sym]
        readonly = ctrl.readonly_assocs.include?(assoc[:name]) || assoc[:readonly] || ctrl.readonly?
        halt(400, '%s is in readonly mode' % model) if readonly && (post? || delete?)
        struct   = {
                 type: assoc[:type],
                 name: assoc[:name],
               dom_id: assoc[:dom_id] + (action_params[:attached] ? '' : '_detached'),
             readonly: readonly ? true : false, # using true/false here cause it will be converted to string and fed to javascript
             attached: action_params[:attached],
                route: route(action, *action_params__array[0..3]),
          source_item: RearORM.new(ctrl.model, ctrl.pkey)[action_params[:item_id].to_i],
          target_item: orm[params[:target_item_id].to_i]||{},
           source_key: nil,
           target_key: nil,
        }
        if struct[:type] == :belongs_to && (struct[:attached] || struct[:source_item].nil?)
          struct[:source_key], struct[:target_key] =
            assoc[:belongs_to_keys].values_at(:source, :target)
        end
        @reverse_assoc = Struct.new(*struct.keys.map(&:to_sym)).new(*struct.values).freeze
      end
    end
  end

  def define_pane_hooks
    @ctrl.class_exec do
      before :get_index, :get_reverse_assoc, :get_minipane do
        
        conditions = filters_to_sql

        source_item, source_assoc = nil
        if @reverse_assoc && @reverse_assoc.attached
          if source_item = @reverse_assoc.source_item
            source_assoc = @reverse_assoc.name
          else
            conditions = {conditions: {pkey => 0}}
          end
        end

        total_items = source_item ?
          orm.assoc_count(source_assoc, source_item, conditions) :
          orm.count(conditions)

        total_pages = (total_items.to_f / __rear__.ipp.to_f).ceil
        side_pages  = PAGER__SIDE_PAGES
        
        current_page = params[:page].to_i
        current_page = 1 if current_page < 1
        current_page = total_pages if current_page > total_pages

        page_next = current_page + 1
        page_next = nil if page_next > total_pages
        page_prev = current_page - 1
        page_prev = nil if page_prev < 1

        page_min = current_page  - side_pages
        page_min = total_pages   - (side_pages * 2) if (current_page + side_pages) > total_pages
        page_min = 1 if page_min < 1

        page_max = current_page + side_pages
        page_max = side_pages   * 2 if current_page < side_pages
        page_max = total_pages  if page_max > total_pages

        offset = (current_page - 1) * __rear__.ipp
        offset = 0 if offset < 0

        counter = [offset + 1, offset + __rear__.ipp, total_items]
        counter[0] = offset if counter[0] > total_items
        counter[1] = total_items if counter[1] > total_items

        @pager_context = {
           total_items: total_items,
           total_pages: total_pages,
          current_page: current_page,
              page_min: page_min,
              page_max: page_max,
             page_prev: page_prev,
             page_next: page_next,
               counter: counter.map {|n| RearUtils.number_with_delimiter(n)}
        }
        @pager = total_pages > 1 ? reander_p(:pager, @pager_context) : ''
        
        conditions[:limit ] = __rear__.ipp
        conditions[:offset] = offset
        
        if order = order_params_to_sql || __rear__.order_by
          conditions[:order] = order
        end

        @items = if source_item
          orm.assoc_filter(source_assoc, source_item, conditions)
        else
          orm.filter(conditions)
        end
      end
    end
  end

  def define_editor_hooks
    @ctrl.class_exec do
      before :get_edit do
        if (id = action_params[:id].to_i) > 0
          @item = orm[id] || halt(400, "Item with ID %s not found" % id)
          @item_id = id
        else
          @item = @brand_new_item = model.new
          @item_id = 0
        end
      end

    end
  end

  def setup_file_browser
    @ctrl.class_exec do
      before /file_browser/ do
        root = __rear__.file_browser[:root] || halt(400, 'File browser root not set')
        File.directory?(root) || halt(400, '"%s" should be a directory' % escape_html(root))
        @__rear__file_browser_root = root.freeze
        @__rear__file_browser_root_regexp = /\A#{Regexp.escape root}/.freeze
      end
    end
  end
  
end
