class RearORM
  include RearUtils

  attr_reader :model, :pkey

  def initialize model, pkey = :id
    @model, @pkey, @orm = model, pkey, orm(model)
  end

  def [] id
    sequel? ?
      model[id] :
      model.first(conditions: {pkey => id})
  end

  def count conditions = {}
    if sequel?
      sequel_dataset(model, conditions).count
    else
      model.count(conditions)
    end
  end

  def filter conditions = {}
    if sequel?
      sequel_dataset(model, conditions).all
    else
      model.all(conditions)
    end
  end

  def assoc_filter assoc, item, conditions
    if sequel?
      sequel_dataset(item.send('%s_dataset' % assoc), conditions).all
    elsif activerecord?
      limit, offset = conditions.delete(:limit), conditions.delete(:offset)
      result = item.send(assoc, conditions)
      result.respond_to?(:limit) && limit ?
        result.limit(limit).offset(offset || 0) :
        [result].compact
    else
      result = item.send(assoc, conditions)
      result.respond_to?(:size) ? result : [result].compact
    end
  end

  def assoc_count assoc, item, conditions
    if sequel?
      sequel_dataset(item.send('%s_dataset' % assoc), conditions).count
    else
      if result = item.send(assoc)
        result.respond_to?(:count) ? result.count(conditions) : 1
      else
        0
      end
    end
  end

  def delete_multiple *ids
    ids.flatten!
    model.destroy(ids) if @orm == :ar
    model.all(pkey => ids).destroy! if @orm == :dm
    model.filter(pkey => ids).destroy if @orm == :sq
  end

  def sequel?; @orm == :sq; end
  def activerecord?; @orm == :ar; end

  def sequel_dataset dataset, conditions = {}
    filters, limit, offset, order =
      conditions.values_at(:conditions, :limit, :offset, :order)
    ds = limit ? dataset.limit(*[limit, offset].compact) : dataset
    dsf = ds.filter(filters || {})
    if order
      if order.size > 1
        dso = dsf.order(*[order].compact)
      else
        # avoid parenthesis around ( ORDERED BY 'something' DESC )
        dso = dsf.order(order[0])
      end
    else
      dso = dsf
    end
    dso
  end
end
