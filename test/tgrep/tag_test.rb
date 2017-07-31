require_relative '../test_helper'

class TagTest < Minitest::Test
  include MinitestRSpecMocks

  MEMBER_TAG = [
    'amember',
    'path/to/file.h',
    '/^  int   amember  (  lala   )  ;  \\/\\/ comment   $/;"',
    'm',
    'class:Aclass',
    'access:public'
  ].join('	').freeze

  MEMBER_TAG_HASH = {
    name: 'amember',
    filename: 'path/to/file.h',
    pattern: '^  int   amember  (  lala   )  ;  \\/\\/ comment   $',
    kind: 'm',
    class: 'Aclass',
    access: 'public'
  }.freeze

  def test_self_parse
    assert_equal(MEMBER_TAG_HASH, Tgrep::Tag.parse(MEMBER_TAG))
  end

  def test_self_class_name
    assert_equal('Aclass', Tgrep::Tag.class_name(class: 'Aclass', kind: ''))
    assert_equal('Aenum', Tgrep::Tag.class_name(enum: 'Aenum', kind: ''))
    assert_equal('Aref', Tgrep::Tag.class_name(typeref: 'Aref', kind: ''))
    assert_equal('', Tgrep::Tag.class_name(kind: 'c', name: 'Aclass'))
    assert_equal(
      'namespace::Aclass',
      Tgrep::Tag.class_name(namespace: 'namespace', class: 'Aclass', kind: '')
    )
  end

  def test_class_name
    assert_equal('Aclass', Tgrep::Tag.class_name(class: 'Aclass', kind: ''))
    assert_equal('Aenum', Tgrep::Tag.class_name(enum: 'Aenum', kind: ''))
    assert_equal('Aref', Tgrep::Tag.class_name(typeref: 'Aref', kind: ''))
    assert_equal('', Tgrep::Tag.class_name(kind: 'c', name: 'Aclass'))
    assert_equal(
      'namespace::Aclass',
      Tgrep::Tag.class_name(namespace: 'namespace', class: 'Aclass', kind: '')
    )
  end

  def test_self_full_class_name
    assert_equal('Acls', Tgrep::Tag.full_class_name(class: 'Acls', kind: 'm'))
    assert_equal('Aenum', Tgrep::Tag.full_class_name(enum: 'Aenum', kind: 'm'))
    assert_equal('Aref', Tgrep::Tag.full_class_name(typeref: 'Aref', kind: 'm'))
    assert_equal('Acls', Tgrep::Tag.full_class_name(kind: 'c', name: 'Acls'))
    assert_equal(
      'space::Aclass',
      Tgrep::Tag.full_class_name(namespace: 'space', class: 'Aclass', kind: 'm')
    )
  end

  def test_full_class_name
    assert_equal('Acls', Tgrep::Tag.full_class_name(class: 'Acls', kind: 'm'))
    assert_equal('Aenum', Tgrep::Tag.full_class_name(enum: 'Aenum', kind: 'm'))
    assert_equal('Aref', Tgrep::Tag.full_class_name(typeref: 'Aref', kind: 'm'))
    assert_equal('Acls', Tgrep::Tag.full_class_name(kind: 'c', name: 'Acls'))
    assert_equal(
      'space::Aclass',
      Tgrep::Tag.full_class_name(namespace: 'space', class: 'Aclass', kind: 'm')
    )
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
    assert_equal(
      '  int   amember  (  lala   )  ;  // comment   ',
      subject.pattern
    )
    assert_equal('foo', Tgrep::Tag.new({pattern: '^foo'}, '').pattern)
    assert_equal('bar', Tgrep::Tag.new({pattern: 'bar$'}, '').pattern)
    assert_equal('baz', Tgrep::Tag.new({pattern: 'baz'}, '').pattern)
  end

  def test_match_with_full_line_pattern
    tag = Tgrep::Tag.new({pattern: '^foo$'}, '')
    assert(tag.match?('foo'))
    refute(tag.match?('foo '))
    refute(tag.match?(' foo'))
  end

  def test_match_with_start_pattern
    tag = Tgrep::Tag.new({pattern: '^foo'}, '')
    assert(tag.match?('foo'))
    assert(tag.match?('foo '))
    refute(tag.match?(' foo'))
  end

  def test_match_with_end_pattern
    tag = Tgrep::Tag.new({pattern: 'foo$'}, '')
    assert(tag.match?('foo'))
    refute(tag.match?('foo '))
    assert(tag.match?(' foo'))
  end

  # TODO: test <=>, signature, simple_signature

  def test_code
    assert_equal(
      'int amember(lala); // comment',
      Tgrep::Tag.new(MEMBER_TAG_HASH, '').code
    )
  end

  private

  def subject
    @subject ||= Tgrep::Tag.new(MEMBER_TAG_HASH.dup, '/a/base/dir')
  end
end
