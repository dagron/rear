module RearHelpers
  module InstanceMixin

    def pane_columns
      @__rear__pane_columns ||= begin
        pane_columns = columns.select {|c| c.pane?}
        [RearInput.new(pkey)] + case action_name
        when :reverse_assoc
          (assoc_columns = __rear__.assoc_columns) ?
            pane_columns.select {|c| assoc_columns.include? c.name} :
            pane_columns[0..1]
        when :minipane
          pane_columns[0..0]
        else
          pane_columns
        end
      end
    end

    def editor_columns
      @__rear__editor_columns ||= columns.select {|c| c.editor?}
    end

    def columns
      @__rear__columns ||= __rear__.columns.inject([]) do |columns,(name, type, attrs, proc)|
        columns << RearInput.new(name, type, attrs, @brand_new_item, &proc)
      end
    end

    def attrs column, scope
      meth = '%s_attrs' % scope
      column_attrs = column.send(meth)
      return column_attrs if column_attrs.any?
      __rear__.send(meth)
    end

    def render_pane_column column
      render_column column, :pane
    end

    def render_editor_column column
      render_column column, :editor
    end

    def render_column column, scope
      template, value = %w[template value].map {|m| column.send('%s_%s' % [scope, m])}
      locals = if column.optioned?
        options = column.options
        options = Hash[options.zip(options)] if options.is_a?(Array)
        active_options = self.instance_exec(&column.active_options)
        active_options = [active_options] unless active_options.is_a?(Array)
        {options: options, active_options: active_options}
      else
        {value: self.instance_exec(&value)}
      end
      template.is_a?(Proc) ?
        self.instance_exec(&template) :
        render_slim_p(locals) { template_cache(path_to_rear_templates template) }
    end

    def sortable_column? column
      if column.name == pkey || column.order_by? ||
        __rear__.real_columns.any? {|(n,t)| n == column.name}
        sortable_vector column
      end
    end
  end
end
