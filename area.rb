class Area < GameObject

    attr_reader :name, :continent

	def initialize( name, continent, game )
		@continent = continent
		super name, game
	end

end
