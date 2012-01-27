require 'tmpdir'
module PaK43
	class Package
		@pakdir = nil
		@name = nil
		@gitrepo = nil
		@target = nil
		attr_reader :name, :gitrepo, :target
		def initialize(pakdir, name, gitrepo, target)
			@pakdir, @name, @target = [pakdir, name, target]
			@gitrepo = GitRepo.new(gitrepo)
		end

		def rev2commit(revision)
			@gitrepo.commit(revision)
		end

		def install(commit)
			::Dir.mktmpdir('pak43-', @target) do |unpack_dir|
				# unpack the commit
				for filename in commit.fulltree do
					dirname = ::File.dirname(filename)
					dstdir = ('.' === dirname) ? unpack_dir : '%s/%s' % [unpack_dir, dirname]
					::FileUtils.mkdir_p(dstdir)
					open('%s/%s' % [unpack_dir, filename], 'w') { |fd| commit.gitrepo.blob(filename, commit.sha) { |buf| fd.write(buf) } }
				end

				# make the lists and count checksums
				list4create = []
				list4link = []
				sfv = []
				::Dir.chdir(unpack_dir) do
					::Dir.glob('**/*') do |path|
						if ::File.directory?(path) then
							list4create.push(path)
						else
							list4link.push(path)
							sfv.push({:filename => path, :sha1 => PaK43.sha1(path)})
						end
					end
				end

				# make changes to target
				t = Transaction.new(unpack_dir, @target)
				begin
					list4create.each {|path| t.mkdir(path) }
					list4link.each {|fn| t.link(fn, fn) }
					@pakdir.installed(@name, commit.sha, t.log.select { |item| :dir === item[:type] }.map { |dir| dir[:path] }, sfv)
				rescue Exception
					t.rollback!
					t.rbxl.each {|e| $stderr.puts('ROLLBACK EXCEPTION: %s' % e.message) }
					raise
				end
			end
		end

		def uninstall!
			xl = [] # exception list
			status = @pakdir.installed_info(@name)
			return xl if status.nil?
			for file in status[:files].reverse do
				begin
					filename = '%s/%s' % [@target, file[:filename]]
					raise('SHA1 doesn\'t match, not removing %s' % filename) unless file[:sha1] === PaK43.sha1(filename)
					::File.unlink(filename)
				rescue Exception
					xl.push($!)
				end
			end
			for dir in status[:dirs].reverse do
				begin
					::Dir.rmdir('%s/%s' % [@target, dir])
				rescue Exception
					xl.push($!)
				end
			end
			@pakdir.uninstalled(@name)
			xl
		end

	end
end
