class Area < GameObject

    attr_reader :continent, :rooms, :age, :builders, :credits, :questable, :security, :vnumStart, :vnumEnd, :control

	def initialize( data, game )
		@continent = data[:continent]
        @age = data[:age]
        @builders = data[:builders]
        @credits = data[:credits]
        @questable = data[:questable]
        @security = data[:security]
        @vnumStart = data[:vnumStart]
        @vnumEnd = data[:vnumEnd]
        @control = data[:control]
        @rooms = []
		super data[:name], game
	end

    def set_rooms( rooms )
        @rooms = rooms
    end

end
