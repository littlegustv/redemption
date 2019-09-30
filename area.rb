class Area < GameObject

    attr_reader :age
    attr_reader :builders
    attr_reader :continent
    attr_reader :control
    attr_reader :credits
    attr_reader :gateable
    attr_reader :id
    attr_reader :questable
    attr_reader :rooms
    attr_reader :security

	def initialize( data, game )
        super(data[:name], game)
        @age = data[:age]
        @builders = data[:builders]
		@continent = data[:continent]
        @control = data[:control]
        @credits = data[:credits]
        @gateable = data[:gateable]
        @id = data[:id]
        @questable = data[:questable]
        @rooms = []
        @security = data[:security]
	end

    def occupants
        return @rooms.map { |room| room.occupants }.flatten
    end

    def items
        return @rooms.map { |room| room.items }.flatten
    end

    # alias for @game.destroy_area(self)
    def destroy
        @game.destroy_area(self)
    end

    def db_source_type
        return "Area"
    end

end
