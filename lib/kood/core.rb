module Kood
  extend self

  # Get a list of existing boards
  def boards
    repo.branches.map { |b| Board.new(b.name) unless b.name.eql? 'master' }.compact
  end

  def create_board(board_slug)
    raise "A board with this slug already exists." if boards.include? board_slug
    Board.new(board_slug)
    Card.adapter :git, repo, branch: board_slug
    Card.adapter.write('kood', '')
  end

  # Get the slug of the currently checked out board
  def current_board
    raise "No boards were found." if boards.empty?
    current_board_slug = `cd #{ repo_root } && git rev-parse --abbrev-ref HEAD`.chomp
    Board.new(current_board_slug)
  end

  def current_user
    `cd #{ repo_root } && git config --get user.name`.chomp
  end

  def checkout(board_slug = nil)
    board_slug = current_board.slug if board_slug.nil?
    raise "The specified board does not exist." unless boards.include? board_slug
    Card.adapter :git, repo, branch: board_slug
  end

  # Check if a user is member of the currently checked out board.
  # Returns true on partial matches and works with both name and email
  def is_member(user)
    !(`cd #{ repo_root } && git log --author "#{ user }" -n 1`).chomp.empty?
  end

  def test?
    ENV['RACK_ENV'] == 'test'
  end

  def root
    @root ||= Pathname(File.expand_path("../../../..", __FILE__))
  end

  def repo_root
    @repo_root ||= test? ? root.join('teststorage').to_s : root.join('storage').to_s
  end

  def repo
    @repo ||= begin
      # Init repo and create master branch because some git commands rely on its existence
      new_repo = Grit::Repo.init(repo_root)
      Dir.chdir(repo_root) { `touch kood && git add kood && git commit -m init` }
      new_repo # If this has been done before, the above command will do nothing
    end
  end

  private

  def clean_repo
    @repo = nil # A dirty trick to be used only in the test suite
  end
end
