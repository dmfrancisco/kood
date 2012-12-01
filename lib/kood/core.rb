module Kood
  extend self

  def current_user
    `cd #{ repo_root } && git config --get user.name`.chomp
  end

  # Get or create the core repository
  def repo
    @repo ||= begin
      # Init repo and create master branch because some git commands rely on its existence
      new_repo = Grit::Repo.init(repo_root)
      Dir.chdir(repo_root) { `touch kood && git add kood && git commit -m init` }
      new_repo # If this has been done before, the above command will do nothing
    end
  end

  # Path to the core repository
  def repo_root
    @repo_root ||= test? ? root.join('storage-test').to_s : root.join('storage').to_s
  end

  # Path to where data, such as user configurations and boards, is stored
  def root
    @root ||= Pathname(File.expand_path("~/.kood"))
  end

  private

  def test?
    ENV['RACK_ENV'] == 'test'
  end

  def clean_repo
    @repo = nil # A dirty trick to be used only in the test suite
  end
end
