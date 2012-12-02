require 'spec_helper'

describe Kood::CLI do
  before do
    %w{ refs/heads HEAD }.each { |f| Kood.repo.git.fs_delete(f) } # Delete all branches
    Kood.clean_repo # Force kood to create the master branch again
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
      kood('boards').must_include "bar\n* foo"
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
  end
end
