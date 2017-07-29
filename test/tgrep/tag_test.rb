require_relative '../test_helper'

class TagTest < Minitest::Test
  include MinitestRSpecMocks

  MEMBER_TAG = [
    'amember',
    'path/to/file.h',
    '/^  int amember;  \\/\\/ comment$/;"',
    'm',
    'class:Aclass',
    'access:public'
  ].join('	').freeze

  MEMBER_TAG_HASH = {
    name: 'amember',
    filename: 'path/to/file.h',
    pattern: '^  int amember;  \\/\\/ comment$',
    kind: 'm',
    class: 'Aclass',
    access: 'public'
  }.freeze

  def test_self_parse
    assert_equal(MEMBER_TAG_HASH, Tag.parse(MEMBER_TAG))
  end

  def test_self_class_name
    assert_equal('Aclass', Tag.class_name(class: 'Aclass'))
    assert_equal('Aenum', Tag.class_name(enum: 'Aenum'))
    assert_equal('Atyperef', Tag.class_name(typeref: 'Atyperef'))
    assert_equal('Aclass', Tag.class_name(kind: 'c', name: 'Aclass'))
    assert_equal(
      'namespace::Aclass',
      Tag.class_name(namespace: 'namespace', class: 'Aclass')
    )
  end

  def test_class_name
    expect(Tag).to receive(:class_name).with(MEMBER_TAG_HASH).and_return('cls')
    assert_equal('cls', subject.class_name)
  end

  def test_simple
    assert_equal('amember', subject.name)
    assert_equal('path/to/file.h', subject.filename)
    assert_equal('m', subject.kind)
  end

  def test_absolute_filename
    assert_equal('/a/base/dir/path/to/file.h', subject.absolute_filename)
  end

  def test_pattern
    assert_equal('  int amember;  // comment', subject.pattern)
    assert_equal('foo', Tag.new({pattern: '^foo'}, '').pattern)
    assert_equal('bar', Tag.new({pattern: 'bar$'}, '').pattern)
    assert_equal('baz', Tag.new({pattern: 'baz'}, '').pattern)
  end

  def test_match_with_full_line_pattern
    tag = Tag.new({pattern: '^foo$'}, '')
    assert(tag.match?('foo'))
    refute(tag.match?('foo '))
    refute(tag.match?(' foo'))
  end

  def test_match_with_start_pattern
    tag = Tag.new({pattern: '^foo'}, '')
    assert(tag.match?('foo'))
    assert(tag.match?('foo '))
    refute(tag.match?(' foo'))
  end

  def test_match_with_end_pattern
    tag = Tag.new({pattern: 'foo$'}, '')
    assert(tag.match?('foo'))
    refute(tag.match?('foo '))
    assert(tag.match?(' foo'))
  end

  # TODO: test <=>, code, signature, simple_signature

  private

  def subject
    @subject ||= Tag.new(MEMBER_TAG_HASH.dup, '/a/base/dir')
  end
end
