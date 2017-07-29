require 'set'
require_relative 'config'

module LineNumbers
  RE_CLASS_NAME = /^\s*(class|struct|namespace)\s+([a-zA-Z0-9_]+)[^;]*$/

  def self.add_tag(tag)
    (@tags ||= Hash.new{ |h, k| h[k] = Set.new })[tag.absolute_filename] << tag
  end

  def self.find_line_numbers(filename)
    return if @tags[filename].empty?
    class_name = ''
    line_numbers = Hash.new{ |h, k| h[k] = [] }
    File.open(filename, "r:#{Tgrep::Config::CONFIG.encoding}").each_line.with_index(1) do |line, i|
      class_name = line[RE_CLASS_NAME, 2] || class_name
      line.delete!("\n\r")
      @tags[filename].each do |tag|
        next unless tag.match?(line)
        line_numbers[tag] << [class_name, i]
      end
    end
    forward_line_numbers_to_tags(line_numbers)
  rescue Errno::ENOENT
    @tags.delete(filename)
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
