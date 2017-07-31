module Tgrep
  module Pretty
    if $stdout.tty?
      TPUT_PRIMARY = "#{`tput setaf 2`}#{`tput bold`}".freeze
      TPUT_KEY = `tput setaf 4`.freeze
      TPUT_CODE = `tput setaf 8`.freeze
      TPUT_CLEAR = "#{`tput op`}#{`tput sgr0`}".freeze
    else
      TPUT_PRIMARY = ''.freeze
      TPUT_KEY = ''.freeze
      TPUT_CODE = ''.freeze
      TPUT_CLEAR = ''.freeze
    end

    def self.print(tags, config)
      tag = tags[0]
      puts("#{pretty_class(tag)}#{pretty_name(tag)}#{best_signature(tags)}")
      tags.each do |t|
        filename = config.full_path ? t.absolute_filename : t.filename
        line_numbers = t.line_numbers.empty? ? [0] : t.line_numbers
        puts(" #{TPUT_CODE}# #{t.code}#{TPUT_CLEAR}")
        line_numbers.each do |line_number|
          puts(" #{TPUT_KEY}#{t.kind}#{TPUT_CLEAR} #{filename}:#{line_number}")
        end
      end
      puts
    end

    def self.best_signature(tags)
      tags.map(&:signature).max_by(&:size)
    end

    def self.local_name(tag)
      tag.name.sub(/^#{tag.data[:class]}::/, '')
    end

    def self.pretty_class(tag)
      class_name = tag.class_name
      class_name.empty? ? '' : "#{TPUT_KEY}#{class_name}#{TPUT_CLEAR}::"
    end

    def self.pretty_name(tag)
      name = tag.name.sub(/^#{tag.data[:class]}::/, '')
      "#{TPUT_PRIMARY}#{name}#{TPUT_CLEAR}"
    end
  end
end
