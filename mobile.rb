class Mobile < GameObject

	attr_accessor :room

	def initialize( name, game, room )
		@room = room
		super name, game
	end

end