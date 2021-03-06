# frozen_string_literal: true

require_relative 'option_parser'
require_relative 'version'

module Tgrep
  class Config
    extend OptionParser

    version Tgrep::VERSION

    options_filename '.tgrep'

    options do
      opt('s', :case_sensitive, 'case sensitive')
      opt('i', :no_case_sensitive, 'case insensitive')
      opt(:full_path, 'show full path')
      opt(:outline, 'show the contents of a class')
      arg(
        'c', :class, 'CLASS_RE_PATTERN', 'shrink the output by class name',
        name: :classes
      )
      arg('f', :file_pattern, 'FILE_RE_PATTERN', 'shrink the output by file')
      arg(:encoding, 'ENCODING', 'encoding used to parse files (UTF-8)')
      pos(:tag)
      pos(:tagfile, optional: true)
    end

    def initialize(args)
      @args = args
      @args.each do |key, value|
        define_singleton_method(key) { value } unless respond_to?(key)
      end
      return if self.class.const_defined?(:CONFIG)

      self.class.const_set(:CONFIG, self)
    end

    def to_s
      "Cfg(#{@args})"
    end

    def encoding
      @encoding ||= encodings[-1] || 'utf-8'
    end

    def tag
      @tag ||= @args[:tag].sub(/operator\s*/, 'operator ')
    end

    def tagfile
      @args[:tagfile] ||= find_tagfile
    end

    def open_tagfile
      return $stdin if tagfile == '-'

      File.open(tagfile, "r:#{encoding}")
    end

    def base_dir
      @base_dir ||= File.dirname(tagfile || '.')
    end

    def matcher
      re = tag[-1] == '$' ? "#{tag[0...-1]}\t" : "#{tag}[^\t]*\t"
      re = "^[^\t]*#{re}" if re[0] != '^'
      Regexp.new(re, case_sensitive ? 0 : Regexp::IGNORECASE)
    end

    private

    def find_tagfile
      dir = Dir.pwd
      until File.file?("#{dir}/tags")
        return nil if File.dirname(dir) == dir

        dir = File.dirname(dir)
      end
      "#{dir}/tags"
    end
  end
end
