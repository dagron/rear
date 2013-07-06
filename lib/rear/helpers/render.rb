module RearHelpers
  module InstanceMixin

    def reander *args, &proc
      reander_layout(:layout) { render_slim args, &proc }
    end

    def reander_partial path, *rest
      render_slim_p path_to_rear_templates('%s.slim' % path), *rest
    end
    alias reander_p reander_partial
    
    def reander_layout path, *rest, &proc
      render_slim_l path_to_rear_templates('%s.slim' % path), *rest, &proc
    end
    alias reander_l reander_layout

    def path_to_rear_templates *chunks
      template  = File.join *chunks.map(&:to_s)
      locations = []
      {
        @__rear__templates_path => File.join(app.root, @__rear__templates_path.to_s),
        @__rear__templates_fullpath => @__rear__templates_fullpath,
      }.select {|k,v| k}.each_value do |prefix|
        locations << File.join(prefix, EUtils.class_to_route(self.class.model)) if self.class.respond_to?(:model)
        locations << File.join(prefix, 'shared-templates')
      end
      locations << PATH__TEMPLATES
      locations.each do |p|
        fp = File.join(p, template)
        return explicit_view_path(fp) if File.file?(fp)
      end
      raise ArgumentError, '%s template not found in any of %s paths' % [template,locations*', ']
    end
    
  end
end
