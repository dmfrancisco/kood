require 'minitest/autorun'
require 'kood'

class Test < MiniTest::Unit::TestCase
  include Kood

  def test_no_method_options_removes_class_options_from_options
    kood = CLI.new

    kood.options = { 'foo' => "bar" } # Pass a single method option
    refute kood.send(:no_method_options?)

    kood.options = { 'debug' => "class option" } # Pass a single class option
    assert kood.send(:no_method_options?)

    kood.options = CLI.class_options # Pass several class options
    assert kood.send(:no_method_options?)

    kood.options = { 'foo' => "bar", 'debug' => "class option" } # Method and class opts
    refute kood.send(:no_method_options?)
  end

  def test_shell_argument_type_conversion
    assert_equal    "foo",   Shell.try_convert("foo")
    assert_equal    1,       Shell.try_convert("1")
    assert_in_delta 1.0,     Shell.try_convert("1.0")
    assert_equal    29,      Shell.try_convert("+0000029")
    assert_in_delta -523.49, Shell.try_convert("-0523.49")
  end

  def test_card_pretty_attributes
    card = Card.new

    assert_empty card.pretty_attributes
    assert_empty card.pretty_attributes(['invalid'])
    assert_equal "Date:  #{ card.date }", card.pretty_attributes(['date'])

    card.title = "Lorem Ipsum"
    card.more['hello_world'] = "foo"

    assert_equal "Hello world:  foo", card.pretty_attributes
    output = "Title: #{' '*6} Lorem Ipsum\nHello world:  foo"
    assert_equal output, card.pretty_attributes(['title', 'more'])
    assert_equal output, card.pretty_attributes(['title', 'more', 'invalid'])
  end

  def test_card_find_by_partial_title
    list = List.create(id: "list")

    %w{ fo foo fooo! bar0 bar1 telescope }.each { |t| list.cards.create(title: t) }
    list.cards.create(title: "space", id: "foo")

    assert_equal 2,       Card.find_all_by_partial_title("foo", list: list).length
    assert_equal 3,       Card.find_all_by_partial_title("f", list: list).length
    assert_equal 3,       Card.find_all_by_partial_title_or_id("foo", list: list).length
    assert_equal "foo",   Card.find_by_partial_title!("foo", list: list).title
    assert_equal "foo",   Card.find_by_partial_title!("foo", list: list, unique: true).title
    assert_equal "fooo!", Card.find_by_partial_title!("fooo", list: list, unique: true).title

    assert_raises MultipleDocumentsFound do
      Card.find_by_partial_title!("bar", list: list, unique: true)
    end
    assert_raises MultipleDocumentsFound do
      Card.find_by_partial_title_or_id!("foo", list: list, unique: true)
    end
  end
end
