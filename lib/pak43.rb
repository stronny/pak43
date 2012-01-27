require 'digest'

require 'gitrepo'
require 'transaction'
require 'package'
require 'pakdir'

module PaK43
	VERSION = [1, 0]
	CODENAME = 'airhead'
	BUFSIZE = 65536

	# reads a file in chunks and either returns the file's contents or feeds the chunks to a supplied block
	#
	def self.readfile(filename, bufsize = BUFSIZE, &block)
		res = ''
		open(filename) do |fd|
			until fd.eof? do
				buf = fd.read(bufsize)
				if block_given? then
					yield(buf)
				else
					res += buf
				end
			end
		end
		(block_given?) ? nil : res
	end

	# computes a sha1 checksum of a file; returns it as a hex string
	#
	def self.sha1(filename)
		sha1 = Digest::SHA1.new
		readfile(filename) { |buf| sha1.update(buf) }
		sha1.hexdigest
	end

end
