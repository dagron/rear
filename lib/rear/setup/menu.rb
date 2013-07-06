module RearSetup
  
  # by default all controllers are shown in main menu
  # using the demodulized controller name.
  # 
  # to use a custom label, set it via `menu_label` or its alias - `label`
  # to hide a controller from menu set label to false.
  def menu_label label = nil
    @__rear__menu_label = label.freeze if label || label == false
    @__rear__menu_label.nil? ? default_label : @__rear__menu_label
  end
  alias label menu_label

  # by default controllers will be shown in the menu in the order they was defined.
  # to have a controller shown before other ones set its menu_position to a higher number.
  def menu_position position = nil
    @__rear__menu_position = position.to_i if position
    @__rear__menu_position || 0
  end
  alias position menu_position

  # put current controller under some group.
  #
  # @example put Articles and Pages under Cms dropdown
  #   class Articles < E
  #     include Rear
  #     under :Cms
  #   end
  #   class Pages < E
  #     include Rear
  #     under :Cms
  #   end
  #
  def menu_group group = nil
    @__rear__menu_group = group.to_s if group
    @__rear__menu_group
  end
  alias under menu_group
end
