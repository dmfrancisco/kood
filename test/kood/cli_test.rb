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

  def test_card_pretty_attributes
    card = Kood::Card.new

    assert_equal "", card.pretty_attributes
    assert_equal "", card.pretty_attributes(['invalid'])
    assert_equal "Date:  #{ card.date }", card.pretty_attributes(['date'])

    card.title = "Lorem Ipsum"
    card.more['hello_world'] = "foo"

    assert_equal "Hello world:  foo", card.pretty_attributes
    output = "Title: #{' '*6} Lorem Ipsum\nHello world:  foo"
    assert_equal output, card.pretty_attributes(['title', 'more'])
    assert_equal output, card.pretty_attributes(['title', 'more', 'invalid'])
  end

  def test_card_find_by_partial_title
    list = Kood::List.create(id: "list")

    list.cards.create(list: list, title: "fo")
    list.cards.create(list: list, title: "foo")
    list.cards.create(list: list, title: "fooo!")
    list.cards.create(list: list, title: "bar 0")
    list.cards.create(list: list, title: "bar 1")
    list.cards.create(list: list, title: "telescope")
    list.cards.create(list: list, title: "space", id: "foo")

    assert_equal 2,       Kood::Card.find_all_by_partial_title("foo", list: list).length
    assert_equal 3,       Kood::Card.find_all_by_partial_title("f", list: list).length
    assert_equal 3,       Kood::Card.find_all_by_partial_title_or_id("foo", list: list).length
    assert_equal "foo",   Kood::Card.find_by_partial_title!("foo", list: list).title
    assert_equal "foo",   Kood::Card.find_by_partial_title!("foo", list: list, unique: true).title
    assert_equal "fooo!", Kood::Card.find_by_partial_title!("fooo", list: list, unique: true).title

    begin
      Kood::Card.find_by_partial_title!("bar", list: list, unique: true)
    rescue Exception => e
      assert_equal "Multiple cards match the given criteria.", e.message
    end

    begin
      Kood::Card.find_by_partial_title_or_id!("foo", list: list, unique: true)
    rescue Exception => e
      assert_equal "Multiple cards match the given criteria.", e.message
    end
  end
end
