module RearActions
  include RearConstants

  def get_index
    reander_l(:layout) { reander_p 'pane/layout' }
  end

  def get_minipane
    reander_p 'pane/minipane'
  end

  def get_edit id
    reander_l(:layout) { reander_p 'editor/layout' }
  end

  def get_bulk_edit
    @items = params[:items].to_s.gsub(/[^\d|\s]/, '')
    self.item, self.item_id = model.new, 0
    reander_p 'editor/bulk_edit'
  end

  def post_bulk_edit
    data = Hash[params]
    (columns = data.delete('rear-bulk_editor-crudifier_toggler')).is_a?(Array) ||
      halt(400, 'Nothing to update. Please edit at least one column.')
    items = data.delete('rear-bulk_editor-items').to_s.strip.split
    items.empty? && halt(400, 'No items selected')

    data.reject! {|k,v| !columns.include?(k)}
    updated, failed = [], []
    items.each do |id|
      status, h, body = invoke_via_put(:crud, id, data)
      status == 200 ? updated << id : failed << ['%s Failed' % id, *body]
    end
    failed.any? && styled_halt(500, failed)
    "Successfully Updated Items:\n%s" % updated.join(', ')
  end

  def get_reverse_assoc source_ctrl, assoc_type, assoc_name, item_id, attached = nil
    reander_p 'pane/assocs'
  end

  def post_reverse_assoc source_ctrl, assoc_type, assoc_name, item_id, attached = nil
    case @reverse_assoc.type
    when :belongs_to, :has_one
      @reverse_assoc.source_item.send '%s=' % @reverse_assoc.name, @reverse_assoc.target_item
    when :has_many
      @reverse_assoc.source_item.send(@reverse_assoc.name).each do |ti|
        ti[pkey] == @reverse_assoc.target_item[pkey] && halt(400, "Relation already exists")
      end
      if sequel?
        m = 'add_' << RearInflector.singularize(@reverse_assoc.name)
        @reverse_assoc.source_item.send m, @reverse_assoc.target_item
      else
        @reverse_assoc.source_item.send(@reverse_assoc.name) << @reverse_assoc.target_item
      end
    end
    @reverse_assoc.source_item.save
  end

  def delete_reverse_assoc source_ctrl, assoc_type, assoc_name, item_id, attached = nil
    case @reverse_assoc.type
    when :belongs_to, :has_one
      @reverse_assoc.source_item.send '%s=' % @reverse_assoc.name, nil
    when :has_many
      if sequel?
        (@reverse_assoc.source_item.send(@reverse_assoc.name)||[]).each do |ti|
          next unless ti[pkey] == @reverse_assoc.target_item[pkey]
          m = 'remove_' << RearInflector.singularize(@reverse_assoc.name)
          @reverse_assoc.source_item.send m, ti
        end
      else
        target_items = Array.new(@reverse_assoc.source_item.send(@reverse_assoc.name)||[]).reject do |ti|
          ti[pkey] == @reverse_assoc.target_item[pkey]
        end
        @reverse_assoc.source_item.send '%s=' % @reverse_assoc.name, target_items
      end
    end
    @reverse_assoc.source_item.save
  end

  def delete_delete_selected
    halt(400, '%s is in readonly mode' % model) if readonly?
    if (ids = params[:items].to_s.split.map(&:to_i).select {|r| r > 0}).any?
      orm.delete_multiple(*ids)
    end
  end

  def html_filters partial = false
    partial ? render_filters : reander_p('filters/layout')
  end

  def get_assets(*)
    env['PATH_INFO'] = env['PATH_INFO'].to_s.sub(ASSETS__SUFFIX_REGEXP, '')
    send_files @__rear__assets_fullpath ? @__rear__assets_fullpath :
      (@__rear__assets_path ? File.join(app.root, @__rear__assets_path) : ASSETS__PATH)
  end
end
