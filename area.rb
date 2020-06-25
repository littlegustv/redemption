#
# The Area object.
#
class Area < GameObject

    # @return [Integer] The ID of the area. Returns 0 if it has none.
    attr_reader :id

    # @return [Integer] The age of the area.
    attr_reader :age

    # @return [String] The credits for the area.
    attr_reader :credits

    # @return [Boolean] Whether the area can be gated in or out of.
    attr_reader :gateable

    # @return [Boolean] Whether the area can have quests in it.
    attr_reader :questable

    # @return [Array<Room>] The rooms of the area.
    attr_reader :rooms

    # @return [Integer] Security
    attr_reader :security

    # @return [Integer] The minimum recommended level of the area.
    attr_reader :min

    # @return [Integer] The maximum recommended level of the area.
    attr_reader :max

	#
    # Area initializer.
    #
    # @param [Integer, nil] id The ID of the area, or `nil`.
    # @param [String] name The name of the area.
    # @param [Integer] age The age of the area.
    # @param [Continent] continent The continent the area is on.
    # @param [String] credits The Credits for the area.
    # @param [Boolean] gateable Whether or not the area can be gated in or out of.
    # @param [Boolean] questable Whether or not the area can have quests generate inside.
    # @param [Integer] security The security level of the area.
    #
    def initialize( id, name, age, continent, credits, gateable, questable, security )
        super(name, name.split)
        @id = id || 0
        @age = age || 0
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
        @security = security || 1
        @rooms = []

	end

    #
    # Destroys this area. Destroys all its rooms, removes it from its continent, and then
    # calls Game#destroy_area for removal of the area from global lists.
    #
    # @return [nil]
    #
    def destroy
        super
        @continent.areas.delete self
        @rooms.dup.each do |room|
            room.destroy
        end
        @continent = nil
        @rooms = nil
        Game.instance.destroy_area(self)
        return
    end

    #
    # Gets the inactive area. This is basically just a deactivated Area object that other 
    # gameobjects can reference if they've been removed from the game but still have
    # affects or something else that causes game logic to be executed on them.
    #
    # @return [Area] The inactive area.
    #
    def self.inactive_area
        if @inactive_area.nil?
            @inactive_area = Area.new("inactive area", 0, 15, nil, "none", 0, 0, 1)
            @inactive_area.deactivate
        end
        return @inactive_area
    end

    #
    # Get the Continent object for this area. Can be Continent.inactive_continent if
    # this objects has been destroyed.
    #
    # @return [Continent] The continent. 
    #
    def continent
        return @continent || Continent.inactive_continent
    end

    #
    # Gets all Mobiles AND Players in rooms in this area.
    #
    # @return [Array<Mobile>] The Mobiles and Players.
    #
    def occupants
        return @rooms.map { |room| room.occupants }.flatten
    end

    #
    # The Players in the rooms in this area. Doesn't include mobiles!
    #
    # @return [Array<Player>] The players.
    #
    def players
        return @rooms.map { |room| room.players }.flatten
    end

    #
    # The Mobiles in the rooms in this area. Doesn't include players!
    #
    # @return [Array<Mobile>] The Mobiles.
    #
    def mobiles
        return @rooms.map { |room| room.mobiles }.flatten
    end

    #
    # The Items in the rooms in this area.
    #
    # @return [Array<Item>] The Items.
    #
    def items
        return @rooms.map { |room| room.items }.flatten
    end

end
