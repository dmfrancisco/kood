require 'minitest/autorun'
require 'kood'

class TestCLI < MiniTest::Unit::TestCase
  def test_no_method_options_removes_class_options_from_options
    kood = Kood::CLI.new

    kood.options = { 'foo' => "bar" } # Pass a single method option
    assert_equal false, kood.send(:no_method_options?)

    kood.options = { 'debug' => "class option" } # Pass a single class option
    assert_equal true, kood.send(:no_method_options?)

    kood.options = Kood::CLI.class_options # Pass several class options
    assert_equal true, kood.send(:no_method_options?)

    kood.options = { 'foo' => "bar", 'debug' => "class option" } # Method and class opts
    assert_equal false, kood.send(:no_method_options?)
  end

  def test_shell_argument_type_conversion
    assert_equal "foo",   Kood::Shell.try_convert("foo")
    assert_equal 1,       Kood::Shell.try_convert("1")
    assert_equal 1.0,     Kood::Shell.try_convert("1.0")
    assert_equal 29,      Kood::Shell.try_convert("+0000029")
    assert_equal -523.49, Kood::Shell.try_convert("-0523.49")
  end

  def test_card_printable_attrs_method
    card = Kood::Card.new

    assert_equal "", card.printable_attrs # All default attributes are not set
    assert_equal "Date:  #{ card.date }", card.printable_attrs(['date'])
    assert_equal "", card.printable_attrs(['invalid'])

    card.title = "Lorem Ipsum"
    card.more['hello_world'] = "foo"

    assert_equal "Hello world:  foo", card.printable_attrs
    output = "Title: #{' '*6} Lorem Ipsum\nHello world:  foo"
    assert_equal output, card.printable_attrs(['title', 'more'])
    assert_equal output, card.printable_attrs(['title', 'more', 'invalid'])
  end
end
