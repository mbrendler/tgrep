require_relative '../test_helper'

class TagsTest < Minitest::Test
  def test_empty?
    tags = Tgrep::Tags.new
    assert(tags.empty?)
    tags.add(Tgrep::Tag.new({}, ''))
    refute(tags.empty?)
  end

  # TODO: sort!

  def test_each
    expected_tags = [
      Tgrep::Tag.new({name: 'foo', pattern: 'foo'}, ''),
      Tgrep::Tag.new({name: 'bar', pattern: 'bar'}, '')
    ]
    tags = Tgrep::Tags.new
      .add(expected_tags[0])
      .add(expected_tags[1])
    assert_equal(expected_tags, tags.each.to_a)
  end
end
