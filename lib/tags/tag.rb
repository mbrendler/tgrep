class Tag
  attr_reader :name, :filename, :pattern, :kind, :extra

  def initialize(name, filename, pattern, kind, extra)
    @name = name
    @filename = filename
    @pattern = pattern
    @kind = kind
    @extra = extra
  end

  def indentifier
    "#{extra[:class]}::#{name}#{simple_signature}"
  end

  def line_numbers
    # TODO: if multiple lines, find class and search for the line
    i = 0
    @line_numbers ||= File.open(filename, 'r:iso-8859-1').each_line.reduce([]) do |m, line|
      i += 1
      line.delete("\n\r") == pattern ? m << i : m
    end
  end

  def <=>(other)
    return -1 if kind == 'p'
    return 1 if other.kind == 'p'
    0
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
    new(name, File.join(base_dir, filename), pattern, kind, parse_extra(rest))
  end

  def self.parse_extra(strs)
    Hash[strs.map do |x|
      k, v = x.split(':', 2)
      [k.to_sym, v]
    end]
  end
end
