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
end
