module Rear
  class << self
    MODELS, CONTROLLERS = {}, []

    def register *models, &proc
      models.flatten.each do |model|
        (MODELS[model] ||= []).push(proc)
      end
    end
    alias setup register

    def included base
      if EUtils.is_app?(base)
        RearControllerSetup.init(base)
        CONTROLLERS << base
      else
        raise ArgumentError, '%s is not a Espresso controller' % base
      end
    end

    def controllers
      @controllers ||= begin
        MODELS.each_pair do |model,procs|
          model = RearUtils.extract_constant(model)
          controller = RearUtils.initialize_model_controller(model)
          procs.compact.each {|proc| controller.class_exec(model, &proc)}
          CONTROLLERS << controller
        end
        CONTROLLERS.uniq.each do |controller|
          controller.model && controller.assocs.each_value do |assocs|
            assocs.each_value do |assoc|
              if remote_model = assoc[:remote_model]
                CONTROLLERS << RearUtils.associated_model_controller(remote_model)
              end
            end
          end
        end
        MODELS.clear.freeze
        CONTROLLERS.unshift RearHomeController
        CONTROLLERS.uniq!
        CONTROLLERS.freeze
      end
    end

    def menu
      @menu ||= begin
        containers  = {}
        controllers = Rear.controllers.reject {|c| c == RearHomeController}.
          select {|c| c.label}.inject({}) do |f,c|
            c.menu_group? ?
              ((containers[c.menu_group] ||= []).push(c); f) : f.merge(c=>[c])
        end
        controllers.merge(containers).sort do |a,b|
          b.last.inject(0) {|t,c| t += c.position} <=> a.last.inject(0) {|t,c| t += c.position}
        end
      end
    end

    def app
      @app ||= E.new.mount(controllers)
    end
    alias to_app app
    alias mount! app

    def call env
      app.call env
    end

    def run *args
      app.run *args
    end

  end
end  
