module Kood
  module Git
    extend self

    def current_branch
      out = `git rev-parse --abbrev-ref HEAD`.chomp
      return out, $?.success?
    end

    def checkout(branch, options = { force: false })
      if options[:force]
        `git reset --hard && git checkout #{ branch } -q`
      else
        `git checkout #{ branch } -q`
      end
      return $?.success?
    end

    def pull(branch) # FIXME Assumes remote is called 'origin'
      out = `git pull origin #{ branch } -q 2> /dev/null`
      return out, $?.success?
    end

    def delete_branch(branch)
      `git branch -D #{ branch }`
    end

    private

    def method_missing(method, *args, &block)
      method = method.to_s
      if method =~ /_with_chdir$/
        method.slice! '_with_chdir'
        path = args.delete_at(0)
        Dir.chdir(path) { self.send method, *args, &block }
      else
        super.method_missing(method, *args, &block)
      end
    end
  end
end
