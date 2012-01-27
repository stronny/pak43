require 'fileutils'
module PaK43
	class Pakdir
		@path = nil
		def initialize(path)
			@path = path
		end

		def packages
			res = {}
			return(res) unless ::File.directory?(fn_packages)
			for name in ::Dir.entries(fn_packages) do
				begin
					target = ::File.readlink(fn_target(name))
				rescue
					next
				end
				res[name] = target
			end
			res
		end

		def package(name)
			Package.new(self, name, fn_gitrepo(name), fn_target(name))
		end

		def add_package(name, url, target)
			::FileUtils.mkdir_p(fn_package(name))
			::File.symlink(target, fn_target(name))
			GitRepo.clone(url, fn_package(name), 'gitrepo')
		rescue Exception
			::FileUtils.remove_entry(fn_package(name))
			raise
		end

		def installed(name, commit, dirs, files)
			open(fn_commit(name), 'w') { |fd| fd.write(commit + "\n") }
			open(fn_dirs(name), 'w') { |fd| fd.write(dirs.join("\n") + "\n") }
			open(fn_files(name), 'w') { |fd| fd.write(files.map { |file| '%s %s' % [file[:sha1], file[:filename]] }.join("\n") + "\n") }
		end

		def uninstalled(name)
			::File.unlink(fn_commit(name))
			::File.unlink(fn_dirs(name))
			::File.unlink(fn_files(name))
		end

		def installed?(name)
			::File.exists?(fn_commit(name))
		end

		def installed_info(name)
			return nil unless installed?(name)
			res = {:commit => open(fn_commit(name)) { |fd| fd.read.strip }, :dirs => [], :files => []}
			open(fn_dirs(name)) { |fd| res[:dirs] = fd.read.strip.split("\n") }
			open(fn_files(name)) do |fd|
				fd.each { |line|
					file = line.strip.split(' ', 2)
					res[:files].push({:sha1 => file.first, :filename => file.last})
				}
			end
			res
		end

		def drop_package(name)
			::FileUtils.remove_entry(fn_package(name))
		end

	protected

		def fn_packages
			'%s/packages' % @path
		end
		def fn_package(name)
			'%s/%s' % [fn_packages, name]
		end
		def fn_gitrepo(name)
			'%s/gitrepo' % fn_package(name)
		end
		def fn_target(name)
			'%s/target' % fn_package(name)
		end
		def fn_commit(name)
			'%s/commit' % fn_package(name)
		end
		def fn_dirs(name)
			'%s/dirs' % fn_package(name)
		end
		def fn_files(name)
			'%s/files' % fn_package(name)
		end

	end
end
