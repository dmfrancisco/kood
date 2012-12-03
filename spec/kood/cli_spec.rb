require 'spec_helper'

describe Kood::CLI do
  after do
    %w{ refs/heads HEAD }.each { |f| Kood.repo.git.fs_delete(f) } # Delete all branches
    Kood.clean_repo # Force kood to create the master branch again
    Kood::User.clean_user
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
end
