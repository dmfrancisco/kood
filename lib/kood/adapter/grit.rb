module Grit
  class Repo
    # This code is based on `git.io/git-up`. A special Thank You to the authors.

    def with_stash(options = {})
      stashed = false
      if change_count(options) > 0
        git.stash(options)
        stashed = true
      end
      yield
    ensure
      git.stash(options, "pop") if stashed
    end

    def with_branch(options = {}, branch_name)
      unless head.respond_to?(:name)
        raise "It seems you changed things manually. You are not currently on a branch."
      end
      current_branch = head.name
      checkout(options, branch_name)
      yield
    ensure
      checkout(options, current_branch) unless on_branch? current_branch
    end

    def with_stash_and_branch(stash_options = {}, branch_options = {}, branch_name)
      with_stash(stash_options) do
        with_branch(branch_options, branch_name) { yield }
      end
    end

    def checkout(options = {}, branch_name)
      git.checkout(options, branch_name)
      raise "Failed to checkout #{ branch_name }." unless on_branch? branch_name
    end

    def on_branch?(branch_name = nil)
      head.respond_to?(:name) and head.name == branch_name
    end

    def change_count(options = {})
      options = { :porcelain => true, :'untracked-files' => 'no' }.merge(options)
      git.status(options).split("\n").count
    end
  end
end
