class GameObject

	attr_accessor :name

	def initialize( name, game )
		@name = name
		@game = game
	end

	def update( elapsed )
	end

	def output( message )
	end

	def broadcast( message, targets )
		@game.broadcast message, targets
	end

	def target( query )
		@game.target query
	end

	def to_a
		[ self ]
	end

end
