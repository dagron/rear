module RearSetup

  # tell controller to create a CRUD interface for given model
  # opts and proc will be passed to Espresso's `crudify` helper.
  #
  # @param [Class] model
  # @param [Hash]  opts to be passed to `crudify` method
  # @param [Proc]  proc to be passed to `crudify` method
  #
  def model model = nil, opts = {}, &proc
    return @__rear__model if @__rear__model || model.nil?
    model = RearUtils.extract_constant(model)
    RearUtils.is_orm?(model) ||
      raise(ArgumentError, '"%s" is not a ActiveRecord/DataMapper/Sequel model' % model.inspect)
    @__rear__model = model
    @__rear__default_label = model.name.gsub(/\W/, '_').freeze
    RearControllerSetup.crudify self, model, opts, &proc
  end

  def pkey key = nil
    return unless model
    @__rear__pkey = key if key
    @__rear__pkey ||
      raise(ArgumentError, "Was unable to automatically detect primary key for %s model.
        Please set it manually via `pkey key_name`" % model)
  end

  def order_by *columns
    @__rear__order = columns if columns.any?
    @__rear__order
  end

  def items_per_page n = nil
    @__rear__ipp = n.to_i if n
    @__rear__ipp || 10
  end
  alias ipp items_per_page

  # executed when new item created and when existing item updated
  def on_save &proc
    # const_get(:RearController).
    before :save, &proc
  end

  # executed when existing item updated
  def on_update &proc
    before :update, &proc
  end

  def on_delete &proc
    before :destroy, &proc
  end
  alias on_destroy on_delete

  def readonly!
    @__rear__readonly = true
  end

end
