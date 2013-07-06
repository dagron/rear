module RearActions
  def file_browser
    reander_p 'file_browser/layout'
  end

  def file_browser__tree path = nil
    template, context = path ? ['tree-leaf', {path: path}] : ['tree-root', {}]
    reander_p 'file_browser/' + template, context
  end

  def file_browser__files
    reander_p 'file_browser/files'
  end

  def file_browser__image
    if image = params[:image]
      file = File.join(@__rear__file_browser_root, EUtils.normalize_path(image))
      File.file?(file) || halt(400, '"%s" does not exists or is not a file' % escape_html(image))
      halt send_file(file)
    end
  end

  def post_file_browser
    if given_path = params[:path]
      path = File.join(@__rear__file_browser_root, EUtils.normalize_path(given_path))
      File.directory?(path) || halt(400, '"%s" should be a directory' % escape_html(given_path))
      files = params[:files]
      files = [] unless files.is_a?(Array)
      files.each do |f|
        file = File.join(path, EUtils.normalize_path(f[:filename]))
        FileUtils.mv f[:tempfile], file
        FileUtils.chmod(0755, file)
      end
    end
  end

  def put_file_browser
    if (given_file = params[:file]) && (name = params[:name])
      file = File.join(@__rear__file_browser_root, EUtils.normalize_path(given_file))
      File.file?(file) || halt(400, '"%s" does not exists or is not a file' % escape_html(given_file))
      FileUtils.mv file, File.join(File.dirname(file), File.basename(EUtils.normalize_path(name)))
    end
  end

  def delete_file_browser
    if given_file = params[:file]
      file = File.join(@__rear__file_browser_root, EUtils.normalize_path(given_file))
      File.file?(file) || halt(400, '"%s" does not exists or is not a file' % escape_html(given_file))
      FileUtils.rm file
    end
  end

end
