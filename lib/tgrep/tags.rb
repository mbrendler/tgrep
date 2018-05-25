# frozen_string_literal: true

require 'set'

module Tgrep
  class Tags
    def initialize
      @tags ||= Hash.new { |h, k| h[k] = [] }
    end

    def empty?
      @tags.empty?
    end

    def add(tag)
      return self if @tags[tag.identifier].any? do |t|
        t.filename == tag.filename && t.pattern == tag.pattern
      end
      @tags[tag.identifier] << tag
      self
    end

    def sort!
      @tags.values.each(&:sort!)
      @tags = Hash[@tags.sort_by do |_, tags|
        [tags[0].class_name || '', tags[0].line_numbers[0] || 0]
      end]
    end

    def collect_line_numbers(encoding = 'utf-8')
      tags = Hash.new { |h, k| h[k] = Set.new }
      each { |ts| ts.each { |tag| tags[tag.absolute_filename] << tag } }
      tags.each do |filename, ts|
        forward_line_numbers_to_tags(find_line_numbers(filename, ts, encoding))
      end
    end

    def each
      return to_enum(__method__) unless block_given?
      @tags.each_value(&proc)
    end

    private

    RE_CLASS_NAME = /^\s*(class|struct|namespace)\s+([a-zA-Z0-9_]+)[^;]*$/

    def find_line_numbers(filename, tags, encoding)
      class_name = ''
      line_numbers = Hash.new { |h, k| h[k] = [] }
      File.open(filename, "r:#{encoding}").each_line.with_index(1) do |line, i|
        class_name = line[RE_CLASS_NAME, 2] || class_name
        line.delete!("\n\r")
        tags.each do |tag|
          next unless tag.match?(line)
          line_numbers[tag] << [class_name, i]
        end
      end
      line_numbers
    rescue Errno::ENOENT
      line_numbers
    end

    def forward_line_numbers_to_tags(line_numbers)
      line_numbers.each do |tag, nrs|
        next if nrs.empty?
        if tag.class_name
          nrs1 = nrs.find_all { |klass, _| tag.class_name.end_with?(klass) }
          nrs = nrs1 unless nrs1.empty?
        end
        nrs.each { |_, nr| tag.line_numbers << nr }
      end
    end
  end
end
