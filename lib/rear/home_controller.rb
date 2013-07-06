class RearHomeController < E
  RearControllerSetup.init(self)

  map '/'
  label :Home

  def get_index
    reander_l(:layout) { reander_p(:home) }
  end
end
