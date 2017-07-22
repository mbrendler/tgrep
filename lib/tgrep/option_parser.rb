module OptionParser
  class Error < StandardError
  end

  def options_filename(filename)
    dir = Dir.pwd
    until File.file?("#{dir}/#{filename}")
      break if File.dirname(dir) == dir
      dir = File.dirname(dir)
    end
    filename = "#{dir}/#{filename}"
    @options_filename = File.file?(filename) ? filename : nil
  end

  def define_options(&block)
    @block = block
  end

  def parse(args)
    usage if args.delete('-h') || args.delete('--help')
    new(parse_args(options_from_file + args))
  rescue Error => e
    $stderr.puts(e)
    usage(1)
  end

  def options_from_file
    return [] if @options_filename.nil?
    File.readlines(@options_filename).map{ |l| l[0..-2] }
  end

  def parse_args(args)
    parser = Parser.new(args)
    parser.instance_exec(&@block)
    parser.parsed
  end

  def usage(exit_code = 0)
    help = Help.new(File.basename(@options_filename))
    help.instance_exec(&@block)
    help.print
    exit(exit_code)
  end

  class Parser
    attr_reader :parsed

    def initialize(args)
      @args = args
      @parsed = {}
    end

    def pos(name, _type = nil, optional: false)
      @parsed[name] = @args.delete_at(0)
      return if optional || @parsed[name]
      raise Error, "missing argument - #{name}"
    end

    def opt(short_option = nil, name, _help)
      @parsed[name] = !!(
        (short_option && @args.delete("-#{short_option}")) ||
        @args.delete(_long_option(name))
      )
    end

    def arg(short_option = nil, long_option, _type, _help, name: "#{long_option}s")
      result = []
      ["-#{short_option}", _long_option(long_option)].each do |option|
        next if option == '-'
        while (i = @args.index(option))
          @args.delete_at(i)
          result << @args.delete_at(i)
        end
      end
      @parsed[name.to_sym] = result.compact
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

    def print
      puts "#{$PROGRAM_NAME} [OPTIONS] #{@positional.join(' ')}\n\n"
      max_left = @options.map{ |x| x[0].size }.max
      @options.each do |option, help|
        puts("  #{option.ljust(max_left)} -- #{help}")
      end
      puts
      puts "All options can be written into a '#{@options_filename}'."
      puts 'This file is searched in the current directory and all its parrents.'
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
      option = "--#{long_option}"
      return if @args[@offset] == option
      return unless @args[@offset].start_with?("#{option}=")
      _, value = @args[@offset].split('=', 2)
      @args[@offset] = value
      @args.insert(@offset, option)
      @offset += 1
    end
  end
end
