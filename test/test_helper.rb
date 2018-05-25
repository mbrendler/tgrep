# frozen_string_literal: true

require 'minitest/autorun'
require 'rspec/mocks'
require_relative '../lib/tgrep'

# inspired by https://github.com/codeodor/minitest-rspec_mocks
module MinitestRSpecMocks
  include RSpec::Mocks::ExampleMethods

  def before_setup
    ::RSpec::Mocks.setup
    super
  end

  def after_teardown
    ::RSpec::Mocks.verify
  ensure
    ::RSpec::Mocks.teardown
    super
  end
end
