module RearConstants

  PATH__TEMPLATES = (File.expand_path('../templates', __FILE__) + '/').freeze
  
  ASSETS__PATH = (File.expand_path('../../../assets', __FILE__) + '/').freeze
  ASSETS__SUFFIX = '-rear'.freeze
  ASSETS__SUFFIX_REGEXP = /#{Regexp.escape ASSETS__SUFFIX}\Z/.freeze

  image_files = %w[.bmp .gif .jpg .jpeg .png .svg .ico .tif .tiff]
  ASSETS__IMAGE_FILES = (image_files.concat(image_files.map(&:upcase))).freeze
  
  video_files = %w[.flv .swf .mpg .mpeg .asf .wmv .mov .mp4 .m4v .avi]
  ASSETS__VIDEO_FILES = (video_files.concat(video_files.map(&:upcase)))

  COLUMNS__HANDLED_TYPES = [
    :string, :text,
    :date, :time, :datetime,
    :radio, :checkbox, :select,
    :boolean
  ].freeze
  COLUMNS__DEFAULT_TYPE  = :string
  COLUMNS__BOOLEAN_MAP   = {true => 'Y', false => 'N'}.freeze
  COLUMNS__PANE_MAX_LENGTH = 255
  
  PAGER__SIDE_PAGES = 5

  FILTERS__HANDLED_TYPES   = COLUMNS__HANDLED_TYPES
  FILTERS__DEFAULT_TYPE    = :string
  FILTERS__DECORATIVE_CMP  = :decorative
  FILTERS__STR_TO_BOOLEAN  = {"true" => true, "false" => false}.freeze
  FILTERS__QUERY_MAP = lambda do |orm|
    # using lambda will always return a new copy of Hash, so no need to deep copy it
    default_query_map = {
       gt: ['%s >  ?', '%s'],
       lt: ['%s <  ?', '%s'],
      gte: ['%s >= ?', '%s'],
      lte: ['%s <= ?', '%s'],
      not: ['%s <> ?', '%s'],
      eql: ['%s =  ?', '%s'],
      
      # use left and right wildcards - '%VALUE%'
      like:   ['%s LIKE ?', '%%%s%'],
      unlike: ['%s NOT LIKE ?', '%%%s%'],

      # use only left  wildcard - exact match for end of line - LIKE '%VALUE'
      _like:   ['%s LIKE ?', '%%%s'],
      _unlike: ['%s NOT LIKE ?', '%%%s'],

      # use only right wildcard - exact match for beginning of line - LIKE 'VALUE%'
      like_:   ['%s LIKE ?', '%s%'],
      unlike_: ['%s NOT LIKE ?', '%s%'],

      in:  ['%s IN ?'],
      csl: ['%s IN ?'], # comma separated list
      FILTERS__DECORATIVE_CMP => []
    }
    {
      ar: default_query_map.merge(:in => ['%s IN (?)'], :csl => ['%s IN (?)']),
      dm: default_query_map,
      sq: default_query_map,
    }[orm]
  end

  ASSOCS__STRUCT = lambda do
    {belongs_to: {}, has_one: {}, has_many: {}}
  end
end
