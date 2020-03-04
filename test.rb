require 'memory_profiler'


class Game
	@@source = 'abcdefghijklmnopqrstuvwxyz'

	def initialize
		@hash = {}
		@array = []
		100000.times do |i|
			puts "[[ #{i} ]]" if i % 1000 == 0
			name = @@source.split("").shuffle.join("")
			short = @@source.split("").shuffle.join("")
			long = (@@source.split("").shuffle.join("")) * 10
			# @hash[ name ] = Test.new( name, short, long, self )
			@array.push Test.new( name, short, long, self )
		end
	end
end

class Test
	def initialize( name, short, long, game )
		@name = name
		@short = short
		@long = long
		@game = game
	end
end

MemoryProfiler.start

game = Game.new

report = MemoryProfiler.stop
report.pretty_print
