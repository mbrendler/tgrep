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
        # next if class_name && tag.class_name && !tag.class_name.end_with?(class_name)
        line_numbers[tag] << [class_name, i]
      end
    end
    line_numbers.each do |tag, nrs|
      next if nrs.empty?
      if nrs.size == 1
        tag.add_line_number(nrs[0][1])
        next
      end
      if tag.class_name
        nrs1 = nrs.find_all{ |(class_name, _)| tag.class_name.end_with?(class_name) }
        nrs = nrs1 unless nrs1.empty?
      end
      nrs.each{ |_, nr| tag.add_line_number(nr) }
    end
  end
end
