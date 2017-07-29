require_relative '../test_helper'

class TagNameCaseSensitiveCompareTest < Minitest::Test
  def test_match?
    assert(Tgrep::TagNameCaseSensitiveCompare.new('foo').match?('foobar'))
    refute(Tgrep::TagNameCaseSensitiveCompare.new('foo').match?('barfoo'))
    refute(Tgrep::TagNameCaseSensitiveCompare.new('foo').match?('fOObar'))
  end
end

class TagNameCaseInSensitiveCompareTest < Minitest::Test
  def test_match?
    assert(Tgrep::TagNameCaseInSensitiveCompare.new('foo').match?('foobar'))
    refute(Tgrep::TagNameCaseInSensitiveCompare.new('foo').match?('barfoo'))
    assert(Tgrep::TagNameCaseInSensitiveCompare.new('foo').match?('fOObar'))
  end
end
