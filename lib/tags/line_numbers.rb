module LineNumbers
  def self.add_tag(tag)
    (@tags ||= Hash.new{ |h, k| h[k] = [] })[tag.filename] << tag
  end

  def self.find_line_numbers(filename)
    File.open(filename, 'r:iso-8859-1').each_line.with_index(1) do |line, i|
      @tags[filename].each do |tag|
        tag.add_line_number(i) if line.delete("\n\r") == tag.pattern
      end
    end
  end
end
