require_relative '../test_helper'

TestConfig = Struct.new(:args) do
  extend Tgrep::OptionParser

  options_filename '__options_file__'

  options do
    pos(:arg1)
    pos(:arg2)

    opt(:only_long_opt, 'help about only-long-opt')
    opt('s', :with_short_opt, 'help about with_short_opt')

    arg(:only_long_arg, 'TYPE', 'help about only-long-arg')
    arg('a', :with_short_arg, 'TYPE', 'help about with-short-arg')
  end
end

class OptionParserTest < Minitest::Test
  SUBJECT = TestConfig.parse(%w[
    --only-long-opt
    --with-short-arg s1
    foo
    --with-short-arg=s2
    -a s3
    bar
    --with-short-opt
    --only-long-arg l1
  ])

  def test_possitional
    assert_equal('foo', SUBJECT.args[:arg1])
    assert_equal('bar', SUBJECT.args[:arg2])
  end

  def test_options
    assert(SUBJECT.args[:only_long_opt])
    assert(SUBJECT.args[:with_short_opt])
  end

  def test_short_option
    subject = TestConfig.parse(%w[-s])
    assert(subject.args[:with_short_opt])
  end

  def test_not_given_option
    subject = TestConfig.parse([])
    refute(subject.args[:only_long_opt])
    refute(subject.args[:with_short_opt])
  end

  def test_arguments
    assert_equal(['l1'], SUBJECT.args[:only_long_args])
    assert_equal(%w[s1 s2 s3], SUBJECT.args[:with_short_args])
  end

  def test_not_given_argument
    subject = TestConfig.parse([])
    assert_nil(subject.args[:only_long_args])
    assert_nil(subject.args[:with_short_args])
  end

  def test_short_option_normalisation
    subject = TestConfig.parse(%w[-sahello -aworld])
    assert(subject.args[:with_short_opt])
    assert_equal(%w[hello world], subject.args[:with_short_args])
  end

  def test_read_options_from_file
    File.write('__options_file__', "-s\n--only-long-arg=a1")
    subject = TestConfig.parse([])
    assert(subject.args[:with_short_opt])
    assert_equal(['a1'], subject.args[:only_long_args])
  ensure
    File.delete('__options_file__')
  end

  def test_overwrite_options_from_file_with_arguments
    File.write('__options_file__', '--only-long-arg=a1')
    subject = TestConfig.parse(['--only-long-arg=a2'])
    assert_equal(%w[a1 a2], subject.args[:only_long_args])
  ensure
    File.delete('__options_file__')
  end
end
