module RearUtils
  include RearConstants
  
  # just define controller, do not set model
  def initialize_model_controller model
    return model.const_get(:RearController) if model.const_defined?(:RearController)
    ctrl = model.const_set(:RearController, Class.new(E))
    RearControllerSetup.init(ctrl)
    ctrl.map EUtils.class_to_route(model)
    ctrl.model model
    ctrl
  end
  module_function :initialize_model_controller

  def associated_model_controller model, ensure_mounted = false
    ctrl = ObjectSpace.each_object(Class).find do |o|
      EUtils.is_app?(o) && o.respond_to?(:model) && o.model == model
    end
    unless ctrl
      ctrl = initialize_model_controller(model)
      ctrl.label(false) # automatically generated controllers not shown in menu
    end
    ctrl.mounted? || ctrl.mount if ensure_mounted
    ctrl
  end
  module_function :associated_model_controller

  def extract_assocs model, *args
    send('extract_%s_assocs' % orm(model), model, *args)
  end
  module_function :extract_assocs

  def extract_associated_ar_model model, assoc
    class_name = assoc.options[:class_name] ||
      RearInflector.camelize(RearInflector.singularize(assoc.name.to_s))
    if (ns = class_name.to_s.split('::')).size > 1
      return ns.inject(Object) {|n,c| n.const_get c}
    else
      if (ns = model.name.split('::')).size > 1
        ns.pop
        model_namespace = ns.inject(Object) {|n,c| n.const_get c}
      else
        model_namespace = Object
      end
      return model_namespace.const_get(class_name)
    end
    nil
  end
  module_function :extract_associated_ar_model

  def extract_ar_assocs model, any = false
    model.reflect_on_all_associations.inject(ASSOCS__STRUCT.call) do |map, r|
      
      target_model = extract_associated_ar_model(model, r) ||
        raise(NameError, "Was unable to detect model for %s relation" % r)

      target_pkey = r.options[:primary_key] || target_model.primary_key
      if any || target_pkey  # models without primary key not handled by default
        
        target_pkey = target_pkey.to_sym if target_pkey
        readonly = nil
        belongs_to_keys = {source: nil, target: nil}

        assoc_type = case r.macro
        when :belongs_to
          belongs_to_keys[:source] = (r.options[:foreign_key] || ActiveSupport::Inflector.foreign_key(r.name)).to_sym
          belongs_to_keys[:target] = target_pkey
          :belongs_to
        when :has_one
          readonly = true if r.options[:through]
          :has_one
        else
          :has_many
        end

        map[assoc_type].update r.name => {
                  type: assoc_type,
                  name: r.name,
          remote_model: target_model,
           remote_pkey: target_pkey,
              readonly: readonly,
                dom_id: dom_id_generator(model, assoc_type, r.name),
          belongs_to_keys: belongs_to_keys
        }.freeze
      end
      map
    end.freeze
  end
  module_function :extract_ar_assocs

  def extract_dm_assocs model, any = false
    model.relationships.entries.inject(ASSOCS__STRUCT.call) do |map, r|
      _, target_pkey = extract_dm_columns(r.target_model)
      if any || target_pkey # only models with a primary key are handled by default

        readonly = nil
        belongs_to_keys = {source: nil, target: nil}

        assoc_type = case r.class.name.split('::')[2]
        when 'ManyToOne'
          belongs_to_keys[:source] = r.source_key.first.name.to_sym
          belongs_to_keys[:target] = r.target_key.first.name.to_sym
          :belongs_to
        when 'OneToOne'
          readonly = true if r.options[:through]
          :has_one
        else
          :has_many
        end

        map[assoc_type].update r.name => {
                  type: assoc_type,
                  name: r.name,
          remote_model: r.target_model,
           remote_pkey: target_pkey,
              readonly: readonly,
                dom_id: dom_id_generator(model, assoc_type, r.name),
          belongs_to_keys: belongs_to_keys
        }.freeze
      end
      map
    end.freeze
  end
  module_function :extract_dm_assocs

  def extract_sq_assocs model, any = false
    model.associations.inject(ASSOCS__STRUCT.call) do |map,an|
      a = model.association_reflection(an)
      
      target_model = extract_constant(a[:class_name])
      _, target_pkey = extract_sq_columns(target_model)
      
      if any || target_pkey # only models with a primary key are handled by default
        readonly = nil
        belongs_to_keys = {source: nil, target: nil}

        assoc_type = case a[:type]
        when :many_to_one
          belongs_to_keys[:source] = a[:key]
          belongs_to_keys[:target] = a[:primary_key] || target_pkey
          :belongs_to
        when :one_to_one
          readonly = true if a[:through]
          :has_one
        else
          :has_many
        end

        map[assoc_type].update a[:name] => {
                  type: assoc_type,
                  name: a[:name],
          remote_model: target_model,
           remote_pkey: target_pkey,
              readonly: readonly,
                dom_id: dom_id_generator(model, assoc_type, a[:name]),
            belongs_to_keys: belongs_to_keys
        }.freeze
      end
      map
    end.freeze
  end
  module_function :extract_sq_assocs

  def extract_columns model
    send('extract_%s_columns' % orm(model), model)
  end
  module_function :extract_columns

  def extract_ar_columns model
    unless model.table_exists?
      puts "WARN: %s table does not exists!" % model.table_name
      return [[], :id]
    end
    pkey = nil
    columns = model.columns.inject([]) do |f,c|
      name, type = c.name.to_sym, c.type.to_s.downcase.to_sym
      type = COLUMNS__DEFAULT_TYPE unless COLUMNS__HANDLED_TYPES.include?(type)
      (c.primary && pkey = name) ? f : f << [name, type]
    end
    [columns.freeze, pkey]
  end
  module_function :extract_ar_columns

  def extract_dm_columns model
    pkey = nil
    # TODO: find a way to handle Enum columns
    columns = model.properties.inject([]) do |f,c|
      name, type = c.name.to_sym, c.class.name.to_s.split('::').last.downcase.to_sym
      type = COLUMNS__DEFAULT_TYPE unless [:serial].concat(COLUMNS__HANDLED_TYPES).include?(type)
      (type == :serial && pkey = name) ? f : f << [name, type]
    end
    [columns.freeze, pkey]
  end
  module_function :extract_dm_columns

  def extract_sq_columns model
    pkey = nil
    columns = model.db_schema.inject([]) do |map,(n,s)|
      if s[:primary_key]
        pkey = n
        map
      else
        type = s[:db_type].to_s.split(/\W/).first.to_s.downcase.to_sym
        unless COLUMNS__HANDLED_TYPES.include?(type)
          type = s[:type].to_s.downcase.to_sym
          unless COLUMNS__HANDLED_TYPES.include?(type)
            type = COLUMNS__DEFAULT_TYPE
          end
        end
        map << [n, type]
      end
    end
    [columns.freeze, pkey]
  end
  module_function :extract_sq_columns

  def quote_column model, column
    send('quote_%s_column' % orm(model), model, column)
  end
  module_function :quote_column

  def quote_ar_column model, column
    model.connection.quote_column_name(column)
  end
  module_function :quote_ar_column

  def quote_dm_column model, column
    property = model.properties.find {|p| p.name == column}
    model.repository(model.repository_name).adapter.property_to_column_name(property, false)
  end
  module_function :quote_dm_column

  def quote_sq_column model, column
    model.db.quote_identifier(column)
  end
  module_function :quote_sq_column

  def ar? model
    [:connection, :columns, :reflect_on_all_associations].all? do |m|
      model.respond_to?(m)
    end
  end
  module_function :ar?

  def dm? model
    [:repository, :properties, :relationships].all? do |m|
      model.respond_to?(m)
    end
  end
  module_function :dm?

  def sq? model
    [:db_schema, :columns, :dataset, :associations].all? do |m|
      model.respond_to?(m)
    end
  end
  module_function :sq?

  def orm model
    [:ar, :dm, :sq].find {|o| send('%s?' % o, model)}
  end
  alias is_orm? orm
  module_function :orm
  module_function :is_orm?

  def number_with_delimiter n
    n.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\1,')
  end
  module_function :number_with_delimiter

  def normalize_html_attrs attrs
    (attrs||{}).inject({}) {|h,(k,v)| h.merge k.to_s.downcase => v}
  end
  module_function :normalize_html_attrs

  def dom_id_generator *args
    (args + [args.__id__]).flatten.join('__').gsub(/\W+/, '')
  end
  module_function :dom_id_generator

  def extract_constant smth
    return Object.const_get(smth) if smth.is_a?(Symbol)
    return smth.sub('::', '').split('::').inject(Object) {|o,c| o.const_get(c)} if smth.is_a?(String)
    smth
  end
  module_function :extract_constant

end
