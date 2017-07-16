require_relative 'option_parser'
require_relative 'line_matchers'

class Config
  extend OptionParser

  define_options do
    opt(:he_he, 'help of he-he')
    arg('s', :ha_ha, 'TYPE', 'help of ha-ha')
  end

  define_options do
    opt(:outline, 'show the contents of a class')
    opt('E', :re, 'use regular expressions as TAG')
    opt('I', :case_sensitive, 'case sensitive')
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
    return $stdout if tagfile == '-'
    open(tagfile, "r:#{encoding}")
  end

  def encoding
    # TODO
    'iso-8859-1'
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
    File.dirname(tagfile || '')
  end

  def matcher
    return /#{tag}/ if re
    return TagNameCaseSensitiveCompare.new("#{tag}\t".freeze) if case_sensitive
    TagNameCaseInSensitiveCompare.new("#{tag.downcase}\t".freeze)
  end
end
