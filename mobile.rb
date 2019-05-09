class Mobile < GameObject

	def initialize( name, game, room )
		@room = room
		super name, game
	end

end