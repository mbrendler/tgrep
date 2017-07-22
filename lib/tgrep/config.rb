require_relative 'option_parser'
require_relative 'line_matchers'

class Config
  extend OptionParser

  options_filename '.tgrep'

  define_options do
    opt('Q', :literal, 'match TAG literally')
    opt('s', :case_sensitive, 'case sensitive')
    opt(:full_path, 'show full path')
    opt(:outline, 'show the contents of a class')
    arg(
      'c', :class, 'CLASS_RE_PATTERN', 'shrink the output by class name',
      name: :classes
    )
    arg('f', :file_pattern, 'FILE_RE_PATTERN', 'shrink the output by file')
    pos(:tag)
    pos(:tagfile, optional: true)
  end

  attr_reader :args

  def initialize(args)
    @args = args
    @args.each do |key, value|
      define_singleton_method(key){ value } unless respond_to?(key)
    end
  end

  def to_s
    "Cfg(#{@args})"
  end

  def open_tagfile
    return $stdin if tagfile == '-'
    open(tagfile, "r:#{encoding}")
  end

  def encoding
    # TODO
    'iso-8859-1'
  end

  def tag
    @tag ||= args[:tag].sub(/operator\s*/, 'operator ')
  end

  def tagfile
    @args[:tagfile] || find_tagfile
  end

  def find_tagfile
    dir = Dir.pwd
    until File.file?("#{dir}/tags")
      return nil if File.dirname(dir) == dir
      dir = File.dirname(dir)
    end
    "#{dir}/tags"
  end

  def base_dir
    @base_dir ||= File.dirname(tagfile || '.')
  end

  def matcher
    if literal
      return TagNameCaseSensitiveCompare.new(tag) if case_sensitive
      return TagNameCaseInSensitiveCompare.new(tag.downcase)
    end
    re = tag[-1] == '$' ? "#{tag[0...-1]}\t" : "#{tag}[^\t]*\t"
    Regexp.new(re, case_sensitive ? 0 : Regexp::IGNORECASE)
  end
end
