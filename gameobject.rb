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

	def to_a
		[ self ]
	end

end