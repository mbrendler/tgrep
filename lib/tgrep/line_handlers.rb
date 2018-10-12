# frozen_string_literal: true

module Tgrep
  module LineHandlers
    def self.line_handler(config, tags)
      if config.outline
        outline_line_handler(config, tags)
      else
        default_line_handler(config, tags)
      end
    end

    def self.outline_line_handler(config, tags)
      proc do |line|
        next if line.start_with?('!_TAG_')

        hash = Tag.parse(line)
        next if Tag.full_class_name(hash) != config.tag

        tags.add(Tag.new(hash, config.base_dir))
      end
    end

    def self.default_line_handler(config, tags)
      matcher = config.matcher
      proc do |line|
        next if line.start_with?('!_TAG_')
        next unless matcher.match?(line)

        hash = Tag.parse(line)
        next unless check_patterns(hash[:filename], config.file_patterns)
        next unless check_patterns(Tag.full_class_name(hash), config.classes)

        tags.add(Tag.new(hash, config.base_dir))
      end
    end

    def self.check_patterns(str, patterns)
      return true if patterns.empty?

      patterns.any? { |pattern| /#{pattern}/.match?(str) }
    end
  end
end
