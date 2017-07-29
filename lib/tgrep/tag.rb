require_relative 'line_numbers'

module Tgrep
  class Tag
    # see `ctags --list-kinds`:
    KIND_ORDER = 'ncsugtdpfemvxl'.chars.freeze
    attr_reader :data

    def initialize(data, base_dir)
      @data = data
      @base_dir = base_dir
    end

    %i[name filename kind].each{ |name| define_method(name){ @data[name] } }

    def class_name
      self.class.class_name(@data)
    end

    def absolute_filename
      File.join(@base_dir, filename)
    end

    def pattern
      @pattern ||= data[:pattern].dup.tap do |p|
        p.slice!(0) if start_pattern?
        p.slice!(-1) if end_pattern?
        p.gsub!('\\/', '/')
      end
    end

    def match?(line)
      return line == pattern if start_pattern? && end_pattern?
      return line.start_with?(pattern) if start_pattern?
      return line.end_with?(pattern) if end_pattern?
      line.include?(pattern)
    end

    def identifier
      @identifier ||= begin
        identifier = "#{name}#{simple_signature}"
        if class_name && !name.start_with?(class_name)
          return "#{class_name}::#{identifier}"
        end
        identifier
      end
    end

    def add_line_number(nr)
      (@line_numbers ||= []) << nr
    end

    def line_numbers
      return @line_numbers if instance_variable_defined?(:@line_numbers)
      LineNumbers.find_line_numbers(absolute_filename)
      @line_numbers ||= []
    end

    def <=>(other)
      kind_cmp = kind_index - other.kind_index
      return kind_cmp unless kind_cmp.zero?
      (line_numbers[0] || 0).to_i - (other.line_numbers[0] || 0).to_i
    end

    def kind_index
      KIND_ORDER.index(kind) || -1
    end

    def code
      @code ||= pattern.dup.tap do |code|
        code.gsub!(/^\^?\s*/, '')
        code.gsub!(/\s*;\s*\$?$/, '')
        code.gsub!(/\s+/, ' ')
        code.gsub!(/\(\s*/, '(')
        code.gsub!(/\s*\)/, ')')
      end
    end

    def signature
      @signature ||= data.fetch(:signature, '').tap do |sig|
        sig.tr!("\t", ' ')
        sig.gsub!(/ *, */, ', ')
        sig.gsub!(/  /, ' ')
        sig.gsub!(/ *\( */, '(')
        sig.gsub!(/ *\) */, ')')
        sig.gsub!(/\)const */, ') const')
        sig.gsub!(/ *= */, '=')
        sig.gsub!(/ *& */, '& ')
        sig.gsub!(/ *\* */, '* ')
        sig.gsub!(/ *< */, '<')
        sig.gsub!(/ *> */, '>')
        # sig.gsub!(/<.* .*>)
        sig.sub!('(void)', '()')
      end
    end

    def simple_signature
      signature.dup.tap do |sig|
        sig.gsub!(/=[^,)]*/, '')
        sig.gsub!(/(const-[^ ]+) [^ ]+[,)]/, '\1,')
        sig.gsub!(/([^ ]+) [^ ]+[,)]/, '\1,')
        sig.gsub!(/([^ ,)]+) [,)]/, '\1,')
      end
    end

    private

    def start_pattern?
      @start_pattern ||= data[:pattern][0] == '^'
    end

    def end_pattern?
      @end_pattern ||= data[:pattern][-1] == '$'
    end

    class << self
      def parse(line)
        base, extra = line.split('/;"')
        name, filename, pattern = base.split("\t", 3)
        _, kind, *rest = extra.chomp.split("\t")
        data = {
          name: name,
          filename: filename,
          pattern: pattern[1..-1],
          kind: kind
        }
        add_extra(data, rest)
      end

      def class_name(data)
        data[:class_name] ||= begin
          values = %i[namespace class typeref enum].map{ |k| data[k] }
          values << data[:name] if 'cgnstu'.include?(data[:kind])
          values.compact!
          values.join('::')
        end
      end

      private

      def add_extra(data, extra_strs)
        extra_strs.each do |x|
          k, v = x.split(':', 2)
          data[k.to_sym] = v
        end
        data
      end
    end
  end
end
