module Grit
  # Reopen the `Grit::Repo` class and add some useful methods.
  #
  # This code is based on [git.io/git-up](//git.io/git-up).
  # A special Thank You to the authors.
  #
  class Repo
    # Automatically stashes and unstashes changes in the current branch.
    # @yield The code block is executed after stashing all existing changes, if any. After
    #   executing the block, a `stash pop` applies changes and deletes the stash
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

    # Checkout a specific branch and then return to the previously checked out branch.
    # @yield The code block is executed after a `checkout`. After executing the block,
    #   the previous branch is checked out again.
    # @raise [CheckoutError] If it fails to checkout the branch
    def with_branch(options = {}, branch_name)
      unless head.respond_to?(:name)
        raise CheckoutError, "It seems you changed things manually. You are not on a branch."
      end
      current_branch = head.name
      checkout!(options, branch_name)
      yield
    ensure
      checkout!(options, current_branch) unless on_branch? current_branch
    end

    # Utility method that does both `with_stash` and `with_branch`
    # @see #with_stash
    # @see #with_branch
    def with_stash_and_branch(stash_options = {}, branch_options = {}, branch_name)
      with_stash(stash_options) do
        with_branch(branch_options, branch_name) { yield }
      end
    end

    # Check if the currently checked out branch matches a given branch name
    def on_branch?(branch_name = nil)
      head.respond_to?(:name) and head.name == branch_name
    end

    private

    def change_count(options = {})
      options = { :porcelain => true, :'untracked-files' => 'no' }.merge(options)
      git.status(options).split("\n").count
    end

    def checkout!(options = {}, branch)
      git.checkout(options, branch)
      raise CheckoutError, "Failed to checkout #{ branch }." unless on_branch? branch
    end
  end

  class CheckoutError < StandardError; end
end
