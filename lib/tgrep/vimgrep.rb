# frozen_string_literal: true

module Tgrep
  module Vimgrep
    def self.print(tags, config, output = $stdout)
      tags.each do |tag|
        line_numbers = tag.line_numbers.empty? ? [0] : tag.line_numbers
        line_numbers.each do |line_number|
          filename = config.full_path ? tag.absolute_filename : tag.filename
          output.puts("#{filename}:#{line_number}:#{tag.identifier}")
        end
      end
    end
  end
end
