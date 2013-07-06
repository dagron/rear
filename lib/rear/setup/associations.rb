module RearSetup

  # make some assocs readonly.
  # this is a cosmetic measure - frontend just wont let user modify them
  # but the API for their manipulation will still work
  def readonly_assocs *assocs
    (@__rear__readonly_assocs ||= []).concat(assocs) if assocs.any?
    (@__rear__readonly_assocs ||  [])
  end
  alias readonly_assoc readonly_assocs
  
  # ignore some assocs.
  # this is a cosmetic measure - assocs just wont be displayed on frontend
  # but the API for their manipulation will still work
  def ignored_assocs *assocs
    (@__rear__ignored_assocs ||= []).concat(assocs) if assocs.any?
    (@__rear__ignored_assocs ||  [])
  end
  alias ignored_assoc  ignored_assocs
  alias ignore_assocs  ignored_assocs
  alias ignore_assoc   ignored_assocs

  # when rendering some model in a "remote" association pane,
  # all columns of current model will be displayed.
  #
  # `assoc_columns` allow to set a list of "remotely" displayed columns.
  #
  def assoc_columns *columns
    @__rear__assoc_columns = columns if columns.any?
    @__rear__assoc_columns
  end
  
end
