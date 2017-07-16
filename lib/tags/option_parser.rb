module OptionParser
  def define_options(&block)
    @block = block
  end

  def parse(args)
    usage if args.delete('-h') || args.delete('--help')
    parser = Parser.new(args)
    parser.instance_exec(&@block)
    new(parser.parsed)
  end

  def usage(exit_code = 0)
    help = Help.new
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
      raise "missing argument - #{name}" if !optional && @parsed[name].nil?
    end

    def opt(short_option = nil, name, _help)
      @parsed[name] = !!(
        @args.delete("-#{short_option}") ||
        @args.delete(_long_option(name))
      )
    end

    def arg(short_option = nil, long_option, _type, _help, name: "#{long_option}s")
      result = []
      ["-#{short_option}", _long_option(long_option)].each do |option|
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
    def initialize
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
    end
  end
end
