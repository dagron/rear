module RearSetup

  # set the root and optionally the post-processing proc for file-based columns
  def file_browser root = nil, &proc
    @__rear__file_browser_setup ||= {}
    @__rear__file_browser_setup[:root] ||= root if root
    @__rear__file_browser_setup[:proc] ||= proc if proc
    @__rear__file_browser_setup
  end
end
