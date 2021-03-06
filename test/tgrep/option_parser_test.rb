# frozen_string_literal: true

require_relative '../test_helper'

TestConfig = Struct.new(:args) do
  extend Tgrep::OptionParser

  version 'a-version'

  options_filename '__options_file__'

  options do
    pos(:arg1)
    pos(:arg2, optional: true)

    opt(:only_long_opt, 'help about only-long-opt')
    opt(:no_only_long_opt, 'disables --only-long-opt')
    opt('s', :with_short_opt, 'help about with_short_opt')

    arg(:only_long_arg, 'TYPE', 'help about only-long-arg')
    arg('a', :with_short_arg, 'TYPE', 'help about with-short-arg')
  end
end

class OptionParserTest < Minitest::Test
  include MinitestRSpecMocks

  SUBJECT = TestConfig.parse(
    %w[
      --only-long-opt
      --with-short-arg s1
      foo
      --with-short-arg=s2
      -a s3
      bar
      --with-short-opt
      --only-long-arg l1
    ]
  )

  def test_possitional
    assert_equal('foo', SUBJECT.args[:arg1])
    assert_equal('bar', SUBJECT.args[:arg2])
  end

  def test_positional_optional_is_missing
    subject = TestConfig.parse(['foo'])
    assert_equal('foo', subject.args[:arg1])
    assert_nil(subject.args[:arg2])
  end

  def test_positional_mandatory_is_missing
    expect(TestConfig).to receive(:usage).with(1)
    expect(Kernel).to receive(:warn).with('missing argument - arg1')
    TestConfig.parse([])
  end

  def test_options
    assert(SUBJECT.args[:only_long_opt])
    assert(SUBJECT.args[:with_short_opt])
  end

  def test_no_option
    subject = TestConfig.parse(['--only-long-opt', '--no-only-long-opt', 'foo'])
    refute(subject.args[:only_long_opt])
  end

  def test_short_option
    subject = TestConfig.parse(%w[-s foo])
    assert(subject.args[:with_short_opt])
  end

  def test_not_given_option
    subject = TestConfig.parse(['foo'])
    refute(subject.args[:only_long_opt])
    refute(subject.args[:with_short_opt])
  end

  def test_arguments
    assert_equal(['l1'], SUBJECT.args[:only_long_args])
    assert_equal(%w[s1 s2 s3], SUBJECT.args[:with_short_args])
  end

  def test_no_argument_given
    subject = TestConfig.parse(['foo'])
    assert_equal([], subject.args[:only_long_args])
    assert_equal([], subject.args[:with_short_args])
  end

  def test_short_option_normalisation
    subject = TestConfig.parse(%w[-sahello -aworld foo])
    assert(subject.args[:with_short_opt])
    assert_equal(%w[hello world], subject.args[:with_short_args])
  end

  def test_read_options_from_file
    File.write('__options_file__', "-s\n--only-long-arg=a1")
    subject = TestConfig.parse(['foo'])
    assert(subject.args[:with_short_opt])
    assert_equal(['a1'], subject.args[:only_long_args])
  ensure
    File.delete('__options_file__')
  end

  def test_overwrite_options_from_file_with_arguments
    File.write('__options_file__', '--only-long-arg=a1')
    subject = TestConfig.parse(%w[--only-long-arg=a2 foo])
    assert_equal(%w[a1 a2], subject.args[:only_long_args])
  ensure
    File.delete('__options_file__')
  end

  def test_long_help_option
    expect(TestConfig).to receive(:usage).with(no_args)
    TestConfig.parse(['--help'])
  end

  def test_short_help_option
    expect(TestConfig).to receive(:usage).with(no_args)
    TestConfig.parse(['-h'])
  end

  EXPECTED_USAGE = <<~EXPECTED_USAGE
    #{$PROGRAM_NAME} [OPTIONS] ARG1 [ARG2]

      --only-long-opt           -- help about only-long-opt
      --no-only-long-opt        -- disables --only-long-opt
      -s, --with-short-opt      -- help about with_short_opt
      --only-long-arg TYPE      -- help about only-long-arg
      -a, --with-short-arg TYPE -- help about with-short-arg
      -h, --help                -- show help
      --version                 -- show version

    All options can be written into a '__options_file__'.
    This file is searched in the current directory and all its parents.
  EXPECTED_USAGE

  def test_usage_without_exit_code
    expect(TestConfig).to receive(:exit).with(0)
    out = StringIO.new
    TestConfig.usage(out: out)
    assert_equal(EXPECTED_USAGE, out.string)
  end

  def test_usage_with_exit_code
    expect(TestConfig).to receive(:exit).with(123)
    out = StringIO.new
    TestConfig.usage(123, out: out)
    assert_equal(EXPECTED_USAGE, out.string)
  end

  def test_version_option
    expect(TestConfig).to receive(:version).with(no_args)
    TestConfig.parse(['--version'])
  end

  def test_version
    expect(TestConfig).to receive(:exit).with(0)
    out = StringIO.new
    TestConfig.version(out: out)
    assert_equal("a-version\n", out.string)
  end
end
