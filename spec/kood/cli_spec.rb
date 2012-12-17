require 'spec_helper'

describe Kood::CLI do
  before do
    %w{ refs/heads HEAD }.each { |f| Kood.repo.git.fs_delete(f) }
    Kood.clear_repo # Force kood to create the master branch again
    Kood::Config.clear_instance
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
    it "displays a list on `boards`" do
      kood('board foo', 'board bar')
      kood('boards').must_equal "* foo  (private)\n  bar  (private)"
    end
    it "deletes on `board foo --delete`" do
      kood('board foo')
      kood('board foo -d').must_equal "Board deleted."
    end
    it "deletes the current board on `board --delete`" do
      kood('board foo')
      kood('board --delete').must_equal "Board deleted."
    end
    it "complains deleting an inexistent board" do
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
      kood('boards').must_equal "* foo  (shared)"
    end
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
    it "complains deleting an inexistent list" do
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
    end
    it "complains deleting an inexistent card" do
      kood('card none -d').must_equal "The specified card does not exist."
    end
    it "complains showing an inexistent card" do
      kood('card "Sample card"').must_equal "The specified card does not exist."
    end
    it "displays information on `card 'Sample card'`" do
      kood('card "Sample card" --list hello')
      kood('card "Sample card"').must_include "\u2503 Sample card"
    end
    it "displays information given partial title`" do
      kood('card fo --list hello', 'card foo -l hello')
      kood('card fo').must_include  "\u2503 fo"
      kood('card foo').must_include "\u2503 foo"
      kood('card f').must_include   "\u2503 fo"
    end
    it "displays an empty board if any cards exist" do
      res = kood('cards')
      res.must_include "foo"   # Board title
      res.must_include "hello" # One of the lists
      res.wont_include "bar"   # The other board
    end
  end

  describe "kood edit" do
    before do
      kood('board foo', 'list bar', 'card hello --list bar')
    end

    it "complains if no EDITOR is set" do
      set_env(KOOD_EDITOR: "", EDITOR: "")
      kood('edit hello').must_equal "To edit a card set $EDITOR or $KOOD_EDITOR."
    end
    it "opens the gem with KOOD_EDITOR as highest priority" do
      set_env(KOOD_EDITOR: "kood_editor", EDITOR: "editor")
      kood('edit hello').must_match /^Could not run `kood_editor cards\/.*\.md`\.$/
    end
    it "opens the gem with EDITOR as 2nd highest priority" do
      set_env(KOOD_EDITOR: "", EDITOR: "editor")
      kood('edit hello').must_match /^Could not run `editor cards\/.*\.md`\.$/
    end
    it "notices if the editor exited without changes" do
      set_env(KOOD_EDITOR: "true") # true is a unix command that returns nothing
      out = "The editor exited without changes. Run `kood update` to persist changes."
      kood('edit hello').must_equal out
      kood('card hello -e').must_equal out # Alias
    end
  end

  it "complains if an unknown option is typed" do
    kood('--unknown').must_equal "Unknown switches '--unknown'"
  end
  it "complains if an unknown command is typed" do
    kood('unknown').must_equal "Could not find task \"unknown\"."
  end
end
