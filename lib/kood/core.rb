module Kood
  extend self

  # Path to where data, such as user configurations and boards, is stored
  PROJECT_ROOT = Pathname(File.expand_path("~/.kood")) # TODO Replace with user conf

  def current_user
    `cd #{ root } && git config --get user.name`.chomp
  end

  def current_branch
    `cd #{ root } && git rev-parse --abbrev-ref HEAD`.chomp
  end

  # Path to the repository where boards are stored
  def root
    @_root ||= begin
      proj_root = Kood::PROJECT_ROOT
      test? ? proj_root.join('storage-test').to_s : proj_root.join('storage').to_s
    end
  end

  # Init a repo (and create master branch since some git commands rely on its existence)
  def repo
    @_repo ||= begin
      new_repo = Grit::Repo.init(root)
      master = new_repo.branches.any? { |b| b.name == 'master' } # Check if master exists
      Dir.chdir(root) { `touch k && git add k && git commit -m init` } unless master
      new_repo # If this has been done before, the above command will do nothing
    end
  end

  private

  def test?
    ENV['RACK_ENV'] == 'test'
  end
end
