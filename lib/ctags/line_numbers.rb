module LineNumbers
  RE_CLASS_NAME = /^\s*(class|struct|namespace)\s+([a-zA-Z0-9]+)[^;]*$/

  def self.add_tag(tag)
    (@tags ||= Hash.new{ |h, k| h[k] = [] })[tag.filename] << tag
  end

  def self.find_line_numbers(filename)
    class_name = nil
    line_numbers = Hash.new{ |h, k| h[k] = [] }
    File.open(filename, 'r:iso-8859-1').each_line.with_index(1) do |line, i|
      class_name = line[RE_CLASS_NAME, 2] || class_name
      @tags[filename].each do |tag|
        next if line.delete("\n\r") != tag.pattern
        line_numbers[tag] << [class_name, i]
      end
    end
    forward_line_numbers_to_tags(line_numbers)
  end

  def self.forward_line_numbers_to_tags(line_numbers)
    line_numbers.each do |tag, nrs|
      next if nrs.empty?
      if tag.class_name
        nrs1 = nrs.find_all{ |klass, _| tag.class_name.end_with?(klass) }
        nrs = nrs1 unless nrs1.empty?
      end
      nrs.each{ |_, nr| tag.add_line_number(nr) }
    end
  end
end
