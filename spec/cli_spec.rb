require 'minitest/autorun'
require 'kood'

describe Kood::CLI do
  before do
    Kood.repo.git.fs_delete("refs/heads") # Delete all branches
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

  it "forces unique board slugs" do
    capture_io { Kood::CLI.start %w{ board foo } }
    out = capture_io { Kood::CLI.start %w{ board foo } }.join
    out.must_match "A board with this slug already exists"
  end

  it "displays list of boards on `boards`" do
    capture_io { Kood::CLI.start %w{ board foo } }
    capture_io { Kood::CLI.start %w{ board bar } }
    Kood.boards.map { |b| b.slug }.join(" ").must_equal "bar foo"
  end
end
