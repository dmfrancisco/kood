# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Kood::CLI do
  before do
    %w{ refs/heads HEAD }.each { |f| Kood.repo.git.fs_delete(f) }
    Kood.clear_repo # Force kood to create the master branch again
    Kood::Config.clear_instance
    Adapter::UserConfigFile.clear_conf
  end

  describe "kood board" do
    it "complains if any boards exist" do
      kood('boards').must_equal "No boards were found."
    end
    it "creates on `board foo`" do
      kood('board foo').must_equal "Board created and selected."
      kood('boards').must_equal "* foo  (private)"
    end
    it "forces unique IDs" do
      kood('board foo')
      kood('board foo').must_equal "A board with this ID already exists."
    end
    it "complains if an invalid character is used in the board ID" do
      kood('board foo:').must_equal      "Board ID is invalid."
      kood('board "foo bar"').must_equal "Board ID is invalid."
      kood('board foo@bar').must_equal   "Board ID is invalid."
    end
    it "displays a list on `boards`" do
      kood('board foo', 'board bar')
      kood('boards').must_equal "* foo  (private)\n  bar  (private)"
    end
    it "deletes on `board foo --delete`" do
      kood('board foo', 'board bar')
      kood('board bar -d').must_equal "Board deleted."

      # Same result is excepted if the board has contents
      kood('b bar', 'sw bar', 'l lorem', 'c ipsum -l lorem', 'b sw foo')
      kood('board bar -d').must_equal "Board deleted."
    end
    it "deletes the current board on `board --delete`" do
      kood('board foo')
      kood('board --delete').must_equal "Board deleted."

      # Same result is excepted if the board has contents
      kood('b foo', 'l lorem', 'c ipsum -l lorem')
      kood('board foo -d').must_equal "Board deleted."
    end
    it "complains to delete an inexistent board" do
      kood('board foo -d').must_equal "The specified board does not exist."
    end
    it "switches to board on `board switch`" do
      kood('board foo', 'board bar')
      kood('switch bar').must_equal "Board switched to bar."
      kood('boards').must_equal     "  foo  (private)\n* bar  (private)"
      kood('select bar').must_equal "Board switched to bar." # Alias
    end
    it "creates an external board on `board foo --repo`" do
      kood('board foo -r /tmp/example-git/').must_equal "Board created and selected."
      kood('boards').must_equal "* foo  (private at /tmp/example-git/)"
    end
    # TODO Test the push, pull and sync commands
  end

  describe "kood list" do
    before do
      kood('board foo')
    end
    it "complains if any lists exist" do
      kood('lists').must_equal "No lists were found."
    end
    it "creates on `list bar`" do
      kood('list bar').must_equal "List created."
      kood('lists').must_equal "bar"
    end
    it "forces unique IDs in one board" do
      kood('list bar')
      kood('list bar').must_equal "A list with this ID already exists."
    end
    it "does not force unique IDs between boards" do
      kood('list bar', 'board test', 'switch test')
      kood('list bar').must_equal "List created."
    end
    it "displays a list on `lists`" do
      kood('list hello', 'list world')
      kood('lists').must_equal "hello\nworld"
    end
    it "deletes on `list bar --delete`" do
      kood('list bar')
      kood('list bar -d').must_equal "List deleted."
    end
    it "complains to delete an inexistent list" do
      kood('list bar -d').must_equal "The specified list does not exist."
    end
  end

  describe "kood card" do
    before do
      kood('board foo', 'board bar', 'list hello', 'list world')
    end
    it "creates on `card 'Sample card' -l hello`" do
      kood('card "Sample card" --list hello').must_equal "Card created."
      kood('cards').must_include "Sample card"
    end
    it "deletes on `card 'Sample card' --delete`" do
      kood('card "Sample card" -l hello')
      kood('card "Sample card" -d').must_equal "Card deleted."
      kood('cards').wont_include "Sample card"
    end
    it "complains to delete an inexistent card" do
      kood('card none -d').must_equal "The specified card does not exist."
    end
    it "complains to delete when there are several matches" do
      kood('card "foo 0" -l hello', 'card "foo 1" -l hello')
      kood('card "foo" -d').must_equal "Multiple cards match the given criteria."
      kood('card "bar" -l hello', 'card "bar" -l hello')
      kood('card "bar" -d').must_equal "Multiple cards match the given criteria."
    end
    it "complains to show an inexistent card" do
      kood('card "Sample card"').must_equal "The specified card does not exist."
    end
    it "displays information on `card 'Sample card'`" do
      kood('card "Sample card" --list hello')
      kood('card "Sample card"').must_include "\u2503 Sample card"
    end
    it "displays information given partial title`" do
      kood('card fo --list hello', 'card foo -l hello', 'card lorem -l hello')
      kood('card fo').must_include   "\u2503 fo"
      kood('card foo').must_include  "\u2503 foo"
      kood('card f').must_include    "\u2503 fo"
      kood('card Fo').must_include   "\u2503 fo" # Case-insentive comparison
      kood('card F').must_include    "\u2503 fo"
      kood('card l.*e').must_include "\u2503 lorem"
      kood('card z').must_include    "The specified card does not exist."
    end
    it "displays an empty board if any cards exist" do
      res = kood('cards')
      res.must_include "foo"   # Board title
      res.must_include "hello" # One of the lists
      res.wont_include "bar"   # The other board
    end
    it "supports titles with non-ascii characters" do
      kood('card "hello ümlaut ✔" --list hello')
      kood('card "hello ümlaut ✔"').must_include "hello ümlaut ✔"
    end
    it "supports setting several attributes at once" do
      kood('c lorem -l hello --set title:"Lorem Ipsum" content:"Content"')
      out = kood('card lorem')
      out.must_include "Lorem Ipsum"
      out.must_include "Content"
    end
    it "supports setting custom attributes with different types" do
      kood('c lorem -l hello --set foo:bar priority:1 hello_world:-0.42')
      out = kood('card lorem')
      out.must_include "Foo:          bar"
      out.must_include "Priority:     1"
      out.must_include "Hello world:  -0.42"
    end
    it "prevents the user from overriding the value of the 'list' and 'more' attributes" do
      kood('c lorem -l hello --set list_id:world list:world more:example')
      out = kood('card lorem')
      out.must_include "List:  world"   # This means custom user attributes were set
      out.must_include "More:  example" # instead of modifying the default attributes
    end
    it "unsets attributes on `card sample --unset content:foo`" do
      kood('c lorem -l hello -s content:ex foo:bar')
      kood('c lorem --unset content foo').must_equal "Card updated."
      kood('c lorem').wont_match /content.*foo/i
    end
    it "prevents the user from unsetting the 'title', 'list' and 'more' attributes" do
      out = kood('c lorem -l hello --unset title list list_id more')
      out.must_equal("Card created.\nNo changes to persist.")
    end
    it "adds participants to a card on `card sample --add participants foo`" do
      user_name  = `git config --get user.name `.chomp
      user_email = `git config --get user.email`.chomp
      kood("c lorem -l hello --add participants #{ user_name.split.first }")
      kood('c lorem').must_include "Participants:  #{ user_name } <#{ user_email }>"
    end
    it "adds elements to custom array attributes" do
      kood('c lorem -l hello --add foo one two three')
      kood('c lorem').must_include "Foo:  one, two, three"
    end
    it "removes participants from a card on `c sample --remove participants foo`" do
      first_name  = `git config --get user.name `.chomp.split.first
      kood("c lorem -l hello -a participants #{ first_name } José")
      kood("c lorem --remove participants #{ first_name }")
      kood('c lorem').must_include "Participants:  José"
      kood("c lorem --remove participants José")  # For now, for non-potential members it
      kood('c lorem').wont_include "Participants" # needs to be an exact match
    end
    it "removes elements from custom array attributes" do
      kood('c lorem -l hello --add foo one two three', 'c lorem -r foo one two')
      kood('c lorem').must_include "Foo:  three"
      kood("c lorem --remove foo three")
      kood('c lorem').must_include "Foo:   " # This may change in the future
      kood("c lorem --unset foo")
      kood('c lorem').wont_include "Foo"
    end
    it "copies to the same list on `card 'Sample card' --copy`" do
      kood('card sample -l hello')
      kood('card sample -c').must_equal "Card copied."
      kood('card jambaz -l world')
      kood('card').gsub("\n","").must_match /hello.*world.*sample.*jambaz.*sample/
    end
    it "copies to another list on `card 'Sample card' --copy list`" do
      kood('card sample -l hello')
      kood('card sample -c world').must_equal "Card copied."
      kood('card jambaz -l world')
      kood('card').gsub("\n","").must_match /hello.*world.*sample.*sample.*jambaz/
    end
    it "supports the combination of the copy and delete options" do
      kood('card sample -l hello')
      old_id = kood('card sample').match(/\u2503 (.*) \(created/).captures[0]
      out = kood('card')

      kood("card #{ old_id } -cd").must_equal "Card copied.\nCard deleted."
      new_id = kood('card sample').match(/\u2503 (.*) \(created/).captures[0]
      kood('card').must_equal out.gsub(old_id.slice(0, 8), new_id.slice(0, 8))
    end
    # TODO Test for utf-8 in card descriptions
  end

  describe "kood edit" do
    before do
      kood('board foo', 'list bar', 'card hello --list bar')
    end

    it "complains if no EDITOR is set" do
      set_env(KOOD_EDITOR: "", EDITOR: "")
      kood('edit hello').must_equal "To edit a card set $EDITOR or $KOOD_EDITOR."
    end
    it "edits the card with KOOD_EDITOR as highest priority" do
      set_env(KOOD_EDITOR: "kood_editor", EDITOR: "editor")
      kood('edit hello').must_match /^Could not run `kood_editor cards\/.*\.md`\.$/
    end
    it "edits the card with EDITOR as 2nd highest priority" do
      set_env(KOOD_EDITOR: "", EDITOR: "editor")
      kood('edit hello').must_match /^Could not run `editor cards\/.*\.md`\.$/
    end
    it "notices if the editor exited without changes" do
      set_env(KOOD_EDITOR: "true") # true is a unix command that returns nothing
      out = "The editor exited without changes. Run `kood update` to persist changes."
      kood('edit hello').must_equal out
      kood('card hello -e').must_equal out # Alias

      # Just to make sure it actually opens the file. Since edit uses `system`, programs
      # like `cat` will print to stdout and we can't capture the output here
      set_env(KOOD_EDITOR: "ruby -e \"exit 1 unless File.read(ARGV[0]).include?('title')\"")
      kood('edit hello').wont_match "Could not run"
    end
  end

  it "complains if an unknown option is typed" do
    kood('--unknown').must_equal "Unknown switches '--unknown'"
  end
  it "complains if an unknown command is typed" do
    kood('unknown').must_equal "Could not find task \"unknown\"."
  end
  # it "supports third-party plugins" do # TODO
  #   kood('example foo').must_equal "Hello from example"
  # end
end
