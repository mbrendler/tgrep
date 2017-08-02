require_relative 'tgrep/config'
require_relative 'tgrep/tag'
require_relative 'tgrep/tags'
require_relative 'tgrep/pretty'
require_relative 'tgrep/line_handlers'
require_relative 'tgrep/version'

module Tgrep
  def self.main(args)
    config = Config.parse(args)
    tags = parse_tagfile(config)
    exit(1) if tags.empty?
    tags.collect_line_numbers(config.encoding)
    tags.sort!
    tags.each{ |tag| Pretty.print(tag, config) }
  end

  def self.parse_tagfile(config)
    tags = Tags.new
    handler = LineHandlers.line_handler(config, tags)
    config.open_tagfile.each_line(&handler)
    tags
  end
end
