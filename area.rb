class Area < GameObject

    attr_reader :id
    attr_reader :age
    attr_reader :credits
    attr_reader :gateable
    attr_reader :questable
    attr_reader :rooms
    attr_reader :security
    attr_reader :min
    attr_reader :max

	def initialize( id, name, age, continent, credits, gateable, questable, security )
        super(name, name.split(" "))
        @id = id
        @age = age
		@continent = continent
        @continent.areas << self
        @credits = credits
        range = @credits.match(/{\s?(\d+)\s+(\d+)}/)
        if range
            @min, @max = range[1..2].map(&:to_i)
        else
            @min, @max = [ 45, 51 ]
        end
        @gateable = gateable
        @questable = questable
        @security = security
        @rooms = []

	end

    def destroy
        super
        @continent.areas.delete self
        @rooms.each do |room|
            room.destroy
        end
        Game.instance.destroy_area(self)
    end

    def self.inactive_area
        if @@inactive_area.nil?
            @@inactive_area = Area.new("inactive area", 0, 15, nil, "none", 0, 0, 1)
            @@inactive_area.deactivate
        end
        return @@inactive_area
    end

    def continent
        return @continent || Continent.inactive_continent
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

    def db_source_type_id
        return 5
    end

end
