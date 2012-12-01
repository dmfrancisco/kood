require 'minitest/autorun'
require 'kood'

describe Kood::CLI do
  before do
    %w{ refs/heads HEAD }.each { |f| Kood.repo.git.fs_delete(f) } # Delete all branches
    Kood.send :clean_repo # Force kood to create the master branch again
  end

  it "displays an error on `boards` if any boards exist" do
    out = capture_io { Kood::CLI.start %w{ boards } }.join
    out.must_match "No boards were found"
  end

  it "creates a board on `board foo`" do
    capture_io { Kood::CLI.start %w{ board foo } }.join.must_match "Board created"
    capture_io { Kood::CLI.start %w{ boards } }.join.must_include "foo"
  end

  it "forces unique board IDs" do
    capture_io { Kood::CLI.start %w{ board foo } }
    out = capture_io { Kood::CLI.start %w{ board foo } }.join
    out.must_match "A board with this ID already exists"
  end

  it "displays a list of boards on `boards`" do
    capture_io { Kood::CLI.start %w{ board foo } }
    capture_io { Kood::CLI.start %w{ board bar } }
    capture_io { Kood::CLI.start %w{ boards } }.join.must_include "bar\n* foo"
  end

  it "deletes a board on `board foo --delete`" do
    capture_io { Kood::CLI.start %w{ board foo } }
    capture_io { Kood::CLI.start %w{ board foo -d } }.join.must_include "Board deleted"
  end

  it "deletes the checked out board on `board --delete`" do
    capture_io { Kood::CLI.start %w{ board foo } }
    capture_io { Kood::CLI.start %w{ board --delete } }.join.must_include "Board deleted"
  end

  it "displays an error deleting an inexistent board" do
    out = capture_io { Kood::CLI.start %w{ board foo -d } }.join
    out.must_include "The specified board does not exist"
  end
end
