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
    tag1 = Tgrep::Tag.new({name: 'foo', pattern: 'foo'}, '')
    tag2 = Tgrep::Tag.new({name: 'bar', pattern: 'bar'}, '')
    tags = Tgrep::Tags.new.add(tag1).add(tag2)
    assert_equal([[tag1], [tag2]], tags.each.to_a)
  end
end
