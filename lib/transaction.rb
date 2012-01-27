module PaK43
	class Transaction
		@log = nil
		@rbxl = nil # rollback exception list
		@spref = nil # source prefix
		@dpref = nil # destination prefix
		attr_reader :log, :rbxl
		def initialize(spref = '', dpref = '')
			@log = []
			@rbxl = []
			@spref = spref
			@dpref = dpref
		end

		def mkdir(path)
			begin
				dst = dst(path)
				::Dir.mkdir(dst)
				@log.push({:type => :dir, :path => path, :dst => dst})
			rescue ::Errno::EEXIST
				# debug 'directory already exists'
			end
		end

		def link(old_name, new_name)
			src = src(old_name)
			dst = dst(new_name)
			::File.link(src, dst)
			@log.push({:type => :link, :old => old_name, :new => new_name, :src => src, :dst => dst})
		end

		def rollback!
			for item in @log.reverse do
				begin
					case item[:type]
						when :link then ::File.unlink(item[:dst])
						when :dir then ::Dir.rmdir(item[:dst])
					end
				rescue Exception
					@rbxl.push($!)
				end
			end
		end

	protected

		def src(path)
			return path if path.start_with?('/')
			return path if @spref.empty?
			'%s/%s' % [@spref, path]
		end

		def dst(path)
			return path if path.start_with?('/')
			return path if @dpref.empty?
			'%s/%s' % [@dpref, path]
		end

	end
end
