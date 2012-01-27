module PaK43
	class GitRepo
		@path = nil
		def initialize(path)
			@path = path
		end

		def git(args)
			res = ::Dir.chdir(@path) {`git #{args}`.strip}
			raise('git error') unless $?.success?
			res
		end

		def url
			git('config --get remote.origin.url')
		end

		def commit(revision)
			Commit.new(self, revision)
		end

		def head
			commit('HEAD')
		end

		def bare?
			git('rev-parse --is-bare-repository') === 'true'
		end

		def pull!
			git('pull --quiet')
		end

		def type(object)
			git('cat-file -t "%s"' % object)
		end

		def commit?(object)
			'commit' === type(object)
		end

		def filename(relname)
			'%s/%s' % [@path, relname]
		end

		def self.clone(url, path, name)
			::Dir.chdir(path) do
				`git clone --quiet '#{url}' '#{name}'`
				raise('git error') unless $?.success?
			end
		end

		class Commit
			@gitrepo = nil
			@sha = nil
			@time = nil
			@author_name = nil
			@author_email = nil
			attr_reader :gitrepo, :sha, :time, :author_name, :author_email
			def initialize(gitrepo, revision)
				@gitrepo = gitrepo
				raise('"%s" must be a commit' % revision) unless @gitrepo.commit?(revision)
				@sha, ts, @author_email, @author_name = git('show \'%s\' -s --pretty=format:\'%%H %%at %%aE %%aN\'' % revision).split(' ', 4)
				@time = Time.at(ts.to_i)
			end
			def to_s
				'%s %s <%s> %s' % [@sha, @author_name, @author_email, @time]
			end
			def fulltree
				git('ls-tree -r --full-tree --name-only \'%s\'' % @sha).split("\n")
			end
		protected
			def git(args)
				@gitrepo.git(args)
			end
		end

	end
end
