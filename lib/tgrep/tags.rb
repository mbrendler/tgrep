module Tgrep
  class Tags
    def initialize
      @tags ||= Hash.new{ |h, k| h[k] = [] }
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

    def each(&block)
      return to_enum(__method__) unless block_given?
      @tags.each_value{ |tags| tags.each(&block) }
    end
  end
end
