module Kood
  extend self

  # Path to where data, such as user configurations and boards, is stored
  PROJECT_ROOT = Pathname(File.expand_path("~/.kood")) # TODO Replace with user conf

  def test?
    ENV['RACK_ENV'] == 'test'
  end

  # Default path to the repository where boards are stored
  def root
    @root ||= begin
      proj_root = Kood::PROJECT_ROOT
      test? ? proj_root.join('storage-test').to_s : proj_root.join('storage').to_s
    end
  end

  # Init a repo (and create master branch since some git commands rely on its existence)
  def repo(path = root)
    @repo ||= {}
    @repo[path] ||= begin
      new_repo = Grit::Repo.init(path)
      master = new_repo.branches.any? { |b| b.name == 'master' } # Check if master exists
      Dir.chdir(path) { `touch k && git add k && git commit -m init` } unless master
      new_repo # If this has been done before, the above command will do nothing
    end
  end

  # Live configurations that need to be saved
  class Config
    include Toy::Store

    adapter :git, Kood.repo, branch: 'config'

    # Associations
    list :boards, Kood::Board

    # Attributes
    attribute :custom_repos,     Hash   # Support storing boards in external repos
    attribute :current_board_id, String # Can be stored externally, so checkout isn't enough

    # Only one instance of Config should be created
    def self.instance
      @@instance ||= get_or_create('config')
    end
  end

  def config
    Config.instance # The singleton instance to be used outside this module
  end
end
