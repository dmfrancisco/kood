require 'spec_helper'

describe Kood::CLI do
  before do
    if ENV["KOOD_TEST_OPTS"].to_s.include? '--quick'
      %w{ refs/heads HEAD }.each { |f| Kood.repo.git.fs_delete(f) }
      Kood.clear_repo # Force kood to create the master branch again
      Kood::Config.clear_instance
    else
      FileUtils.rm_rf(Kood.root, secure: true) # Delete the storage folder
    end
  end

  describe "Boards" do
    it "displays an error if any boards exist" do
      kood('boards').must_match "No boards were found"
    end
    it "creates on `board foo`" do
      kood('board foo').must_match "Board created"
      kood('boards').must_include "foo"
    end
    it "forces unique IDs" do
      kood('board foo')
      kood('board foo').must_match "A board with this ID already exists"
    end
    it "displays a list on `boards`" do
      kood('board foo', 'board bar')
      kood('boards').must_include "foo\n  bar"
    end
    it "deletes on `board foo --delete`" do
      kood('board foo')
      kood('board foo -d').must_include "Board deleted"
    end
    it "deletes the checked out board on `board --delete`" do
      kood('board foo')
      kood('board --delete').must_include "Board deleted"
    end
    it "displays an error deleting an inexistent board" do
      kood('board foo -d').must_include "The specified board does not exist"
    end
    it "checks out board on `board checkout`" do
      kood('board foo', 'board bar')
      kood('checkout bar').must_include "Board checked out"
      kood('boards').must_include "  foo\n* bar"
    end
    it "creates an external board on `board foo --repo`" do
      kood('board foo -r /tmp/example-git/').must_match "Board created"
      kood('boards').must_include "foo"
    end
  end

  describe "Lists" do
    before do
      kood('board foo')
    end

    it "displays an error if any lists exist" do
      kood('lists').must_match "No lists were found"
    end
    it "creates on `list bar`" do
      kood('list bar').must_match "List created"
      kood('lists').must_include "bar"
    end
    it "forces unique IDs in one board" do
      kood('list bar')
      kood('list bar').must_match "A list with this ID already exists"
    end
    it "does not force unique IDs between boards" do
      kood('list bar', 'board test', 'checkout test')
      kood('list bar').must_match "List created"
    end
    it "displays a list on `lists`" do
      kood('list hello', 'list world')
      kood('lists').must_include "hello\nworld"
    end
    it "deletes on `list bar --delete`" do
      kood('list bar')
      kood('list bar -d').must_include "List deleted"
    end
    it "displays an error deleting an inexistent list" do
      kood('list bar -d').must_include "The specified list does not exist"
    end
  end

  describe "Cards" do
    before do
      kood('board foo', 'board bar', 'list hello', 'list world')
    end

    it "creates on `card 'Sample card' -l hello`" do
      kood('card "Sample card" --list hello').must_match "Card created"
      kood('cards').must_include "Sample card"
    end
    it "deletes on `card 'Sample card' --delete`" do
      kood('card "Sample card" -l hello')
      kood('card "Sample card" -d').must_include "Card deleted"
    end
    it "displays an error deleting an inexistent card" do
      kood('card none -d').must_include "The specified card does not exist"
    end
    it "displays an error showing an inexistent card" do
      kood('card "Sample card"').must_include "The specified card does not exist"
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
end
