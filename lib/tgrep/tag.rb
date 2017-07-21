require_relative 'line_numbers'

class Tag
  attr_reader :name, :filename, :pattern, :kind, :extra

  # see `ctags --list-kinds`:
  KIND_ORDER = 'ncsugtdpfemvxl'.chars.freeze

  def initialize(name, filename, pattern, kind, base_dir, extra)
    @name = name
    @filename = filename
    @pattern = pattern
    @kind = kind
    @base_dir = base_dir
    @extra = extra
  end

  def indentifier
    "#{class_name}::#{name}#{simple_signature}"
  end

  def class_name
    class_name = extra[:class] || extra[:enum] || extra[:typeref] || (kind == 'c' ? name : nil)
    extra[:namespace] ? "#{extra[:namespace]}::#{class_name}" : class_name
  end

  def add_line_number(nr)
    (@line_numbers ||= []) << nr
  end

  def absolute_filename
    File.join(@base_dir, filename)
  end

  def line_numbers
    return @line_numbers if instance_variable_defined?(:@line_numbers)
    LineNumbers.find_line_numbers(absolute_filename)
    @line_numbers ||= []
  end

  def <=>(other)
    kind_cmp = KIND_ORDER.index(kind) - KIND_ORDER.index(other.kind)
    return kind_cmp unless kind_cmp.zero?
    (line_numbers[0] || 0).to_i - (other.line_numbers[0] || 0).to_i
  end

  def code
    @code ||= pattern.dup.tap do |code|
      code.gsub!(/^\^?\s*/, '')
      code.gsub!(/\s*;\s*\$?$/, '')
      code.gsub!(/\s+/, ' ')
    end
  end

  def signature
    @signature ||= extra.fetch(:signature, '').tap do |sig|
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

  def self.parse(base_dir, line)
    base, extra = line.split('/;"')
    name, filename, pattern = base.split("\t", 3)
    pattern = pattern[2..-2].freeze
    _, kind, *rest = extra.chomp.split("\t")
    new(name, filename, pattern, kind, base_dir, parse_extra(rest))
  end

  def self.parse_extra(strs)
    Hash[strs.map do |x|
      k, v = x.split(':', 2)
      [k.to_sym, v]
    end]
  end
end
