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
    attr_reader :min
    attr_reader :max

	def initialize( data )
        super(data[:name], data[:name].split(" "))
        @age = data[:age]
        @builders = data[:builders]
		@continent = data[:continent]
        @control = data[:control]
        @credits = data[:credits]
        range = @credits.match(/{\s?(\d+)\s+(\d+)}/)
        if range
            @min, @max = range[1..2].map(&:to_i)
        else
            @min, @max = [ 45, 51 ]
        end
        @gateable = data[:gateable]
        @id = data[:id]
        @questable = data[:questable]
        @rooms = []
        @security = data[:security]
	end

    def occupants
        return @rooms.map { |room| room.occupants }.flatten
    end

    def players
        return @rooms.map { |room| room.players }.flatten
    end

    def mobiles
        return @rooms.map { |room| room.mobiles }.flatten
    end

    def items
        return @rooms.map { |room| room.items }.flatten
    end

    # alias for Game.instance.destroy_area(self)
    def destroy
        Game.instance.destroy_area(self)
    end

    def db_source_type
        return "Area"
    end

end
