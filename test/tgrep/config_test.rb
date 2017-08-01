require_relative '../test_helper'

class ConfigTest < Minitest::Test
  SUBJECT = Tgrep::Config.new(
    case_sensitive: false,
    full_path: false,
    outline: false,
    classes: [],
    file_patterns: [],
    encodings: [],
    tag: 'a-tag',
    tagfile: "#{__dir__}/tags"
  )

  def test_case_sensitive
    refute(SUBJECT.case_sensitive)
    assert(Tgrep::Config.new(case_sensitive: true).case_sensitive)
  end

  def test_full_path
    refute(SUBJECT.full_path)
    assert(Tgrep::Config.new(full_path: true).full_path)
  end

  def test_outline
    refute(SUBJECT.outline)
    assert(Tgrep::Config.new(outline: true).outline)
  end

  def test_classes
    assert_equal([], SUBJECT.classes)
    assert_equal(%w[foo bar], Tgrep::Config.new(classes: %w[foo bar]).classes)
  end

  def test_file_patterns
    assert_equal([], SUBJECT.file_patterns)
    assert_equal(
      %w[foo bar],
      Tgrep::Config.new(file_patterns: %w[foo bar]).file_patterns
    )
  end

  def test_encoding
    assert_equal('utf-8', SUBJECT.encoding)
    assert_equal(
      'iso-8859-1',
      Tgrep::Config.new(encodings: ['iso-8859-1']).encoding
    )
  end

  def test_tag
    assert_equal('a-tag', SUBJECT.tag)
  end

  def test_tagfile
    assert_equal("#{__dir__}/tags", SUBJECT.tagfile)
    cd(__dir__) do
      assert_equal("#{__dir__}/tags", Tgrep::Config.new({}).tagfile)
    end
  end

  def test_open_tagfile
    assert_equal("a-tag\tfile\t/^pattern$/;\"\n", SUBJECT.open_tagfile.read)
    assert_equal($stdin, Tgrep::Config.new(tagfile: '-').open_tagfile)
  end

  def test_base_dir
    assert_equal(__dir__, SUBJECT.base_dir)
    assert_equal('.', Tgrep::Config.new(tagfile: '.').base_dir)
    cd(__dir__){ assert_equal(__dir__, Tgrep::Config.new({}).base_dir) }
  end

  def test_matcher
    assert_equal(/^[^	]*a-tag[^	]*	/i, SUBJECT.matcher)
    assert_equal(/^[^	]*a-tag	/i, config(tag: 'a-tag$').matcher)
    assert_equal(/^a-tag	/i, config(tag: '^a-tag$').matcher)
    assert_equal(/^a-tag[^	]*	/i, config(tag: '^a-tag').matcher)

    assert_equal(
      /^a-tag	/,
      config(tag: '^a-tag$', case_sensitive: true).matcher
    )
  end

  private

  def config(options = {})
    Tgrep::Config.new({case_sensitive: false}.merge(options))
  end

  def cd(dir)
    old_dir = Dir.getwd
    Dir.chdir(dir)
    yield
  ensure
    Dir.chdir(old_dir)
  end
end
