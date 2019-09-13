class Area < GameObject

    attr_reader :continent, :rooms, :age, :builders, :credits, :gateable, :questable, :security, :control

	def initialize( data, game )
		@continent = data[:continent]
        @age = data[:age]
        @builders = data[:builders]
        @credits = data[:credits]
        @gateable = data[:gateable]
        @questable = data[:questable]
        @security = data[:security]
        @control = data[:control]
        @rooms = []
		super data[:name], game
	end

    def set_rooms( rooms )
        @rooms = rooms
    end

    def fire_event(event, data)

    end

end
