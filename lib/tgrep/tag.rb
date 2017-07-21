require_relative 'line_numbers'

class Tag
  # see `ctags --list-kinds`:
  KIND_ORDER = 'ncsugtdpfemvxl'.chars.freeze
  attr_reader :data

  def initialize(data, base_dir)
    @data = data
    @base_dir = base_dir
  end

  %i[name filename kind].each do |name|
    define_method(name){ @data[name] }
  end

  def pattern
    @pattern ||= data[:pattern][2..-2].tap{ |p| p.gsub!('\\/', '/') }
  end

  def identifier
    return "#{name}#{simple_signature}" if class_name && name.start_with?(class_name)
    "#{class_name}::#{name}#{simple_signature}"
  end

  def class_name
    self.class.class_name(@data)
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

  def self.parse(line)
    base, extra = line.split('/;"')
    name, filename, pattern = base.split("\t", 3)
    _, kind, *rest = extra.chomp.split("\t")
    data = {name: name, filename: filename, pattern: pattern, kind: kind}
    add_extra(data, rest)
  end

  def self.add_extra(data, extra_strs)
    extra_strs.each do |x|
      k, v = x.split(':', 2)
      data[k.to_sym] = v
    end
    data
  end

  def self.class_name(data)
    class_name = data[:class] || data[:enum] || data[:typeref] || (data[:kind] == 'c' ? data[:name] : nil)
    data[:namespace] ? "#{data[:namespace]}::#{class_name}" : class_name
  end
end
