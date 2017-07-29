module Tgrep
  module OptionParser
    class Error < StandardError
    end

    def options_filename(filename)
      @options_filename = filename
    end

    def options(&block)
      @block = block
    end

    def parse(args)
      return usage if args.delete('-h') || args.delete('--help')
      args = ArgsNormalizer.new(options_from_file + args).normalize(&@block)
      parsed = Parser.new(args, &@block).parsed
      new(parsed)
    rescue Error => e
      $stderr.puts(e.to_s)
      usage(1)
    end

    def usage(exit_code = 0, out: $stdout)
      help = Help.new(@options_filename)
      help.instance_exec(&@block)
      help.print(out)
      exit(exit_code)
    end

    private

    def options_from_file
      options_filename = find_options_filename
      return [] if options_filename.nil?
      File.readlines(options_filename).map{ |l| l.delete("\n\r") }
    end

    def find_options_filename
      dir = Dir.pwd
      until File.file?("#{dir}/#{@options_filename}")
        break if File.dirname(dir) == dir
        dir = File.dirname(dir)
      end
      filename = "#{dir}/#{@options_filename}"
      File.file?(filename) ? filename : nil
    end

    class Parser
      def initialize(args, &block)
        @args = args
        @offset = 0
        @block = block
        @parsed = {}
        @parse_state = :options
      end

      def pos(name, _type = nil, optional: false)
        return if @parse_state != :positional
        return unless @parsed[name].nil?
        @parsed[name] = @args.delete_at(0)
        return if optional || @parsed[name]
        raise Error, "missing argument - #{name}"
      end

      def opt(short_option = nil, name, _help)
        return if @parse_state != :options
        options = [_long_option(name)]
        options << "-#{short_option}" if short_option
        if options.include?(@args[@offset])
          @args.delete_at(@offset)
          @parsed[name] = true
        elsif @parsed[name].nil?
          @parsed[name] = false
        end
      end

      def arg(short = nil, long, _type, _help, name: "#{long}s".to_sym)
        return if @parse_state != :options
        @parsed[name] ||= []
        options = [_long_option(long)]
        options << "-#{short}" if short
        return unless options.include?(@args[@offset])
        @args.delete_at(@offset)
        @parsed[name] << @args[@offset]
        @args.delete_at(@offset)
      end

      def parsed
        return @parsed unless @parsed.empty?
        parse
        @parse_state = :positional
        instance_exec(&@block) if @args.empty?
        parse
        @parsed
      end

      private

      def parse
        @offset = 0
        while @offset < @args.size
          old_size = @args.size
          instance_exec(&@block)
          @offset += 1 if old_size == @args.size
        end
      end

      def _long_option(name)
        "--#{name.to_s.tr('_', '-')}"
      end
    end

    class Help
      def initialize(options_filename)
        @options_filename = options_filename
        @positional = []
        @options = []
      end

      def pos(name, type = nil, optional: false)
        type = (type.nil? ? name.to_s.upcase : type)
        @positional << (optional ? "[#{type}]" : type)
      end

      def opt(short_option = nil, name, help)
        @options << [_options(short_option, name), help]
      end

      def arg(short_option = nil, name, type, help, **_options)
        @options << ["#{_options(short_option, name)} #{type}", help]
      end

      def _options(short_option, name)
        long_option = "--#{name.to_s.tr('_', '-')}"
        return long_option if short_option.nil?
        "-#{short_option}, #{long_option}"
      end

      def print(out)
        out.puts "#{$PROGRAM_NAME} [OPTIONS] #{@positional.join(' ')}\n\n"
        max_left = @options.map{ |x| x[0].size }.max
        @options.each do |option, help|
          out.puts("  #{option.ljust(max_left)} -- #{help}")
        end
        out.puts
        out.puts("All options can be written into a '#{@options_filename}'.")
        out.puts(
          'This file is searched in the current directory and all its parrents.'
        )
      end
    end

    class ArgsNormalizer
      def initialize(args)
        @args = args
        @offset = 0
      end

      def pos(*_); end

      def opt(short_option = nil, _name, _help)
        return if short_option.nil?
        option = "-#{short_option}"
        return if @args[@offset] == option
        return unless @args[@offset].start_with?(option)
        @args[@offset] = "-#{@args[@offset][2..-1]}"
        @args.insert(@offset, option)
        @offset += 1
      end

      def arg(short_option = nil, long_option, _type, _help, **_options)
        handle_short_option_arg(short_option) unless short_option.nil?
        handle_long_option_arg(long_option)
      end

      def normalize(&block)
        @offset = 0
        while @offset < @args.size
          old_size = @args.size
          instance_exec(&block)
          @offset += 1 if old_size == @args.size
        end
        @args
      end

      private

      def handle_short_option_arg(short_option)
        option = "-#{short_option}"
        return if @args[@offset] == option
        return unless @args[@offset].start_with?(option)
        @args[@offset] = @args[@offset][2..-1]
        @args.insert(@offset, option)
        @offset += 1
      end

      def handle_long_option_arg(long_option)
        option = _long_option(long_option)
        return if @args[@offset] == option
        return unless @args[@offset].start_with?("#{option}=")
        _, value = @args[@offset].split('=', 2)
        @args[@offset] = value
        @args.insert(@offset, option)
        @offset += 1
      end

      def _long_option(name)
        "--#{name.to_s.tr('_', '-')}"
      end
    end
  end
end
