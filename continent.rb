#
# The Continent object. 
#
class Continent < GameObject

    # @return [Integer] The ID of the continent. Returns 0 if it has none.
    attr_reader :id

    # @return [String] The preposition for this continent, eg) "on" vs "in" to generate the string "on Terra"
    attr_reader :preposition

    # @return [Array<Area>] The areas that comprise this continent.
    attr_reader :areas

    #
    # Continent initialization.
    #
    # @param [Integer] id The ID for the continent.
    # @param [String] name The name of the continent.
    # @param [String] preposition The preposition (_on_ terra).
    # @param [Integer, nil] recall_room_id The ID of the room that recall will lead to on this
    # continent, or `nil` if there isn't one.
    # @param [Integer, nil] starting_room_id The ID of the room that characters on this continent
    # will start on, or `nil` if there isn't one.
    #
    def initialize( id, name, preposition, recall_room_id, starting_room_id )
        super(name, name)
        @id = id || nil
        @preposition = preposition
        @recall_room_id = recall_room_id
        @starting_room_id = starting_room_id
        @areas = []
    end

    #
    # Destroys this continent. Destroy all its areas, and then call Game#destroy_continent for removal
    # of the continent from global lists.
    #
    # @return [nil]
    #
    def destroy
        super
        @areas.dup.each do |area|
            area.destroy
        end
        @areas = nil
        Game.instance.remove_continent(self)
        return
    end

    #
    # Gets the inactive continent. This is basically just a deactivated Continent object that other
    # gameobjects can reference if they've been removed from the game but still have
    # affects or something else that causes game logic to be executed on them.
    #
    # @return [Continent] The inactive continent.
    #
    def self.inactive_continent
        if @inactive_continent.nil?
            @inactive_continent = Continent.new(0, "inactive continent", "on", 0, 0)
            @inactive_continent.deactivate
        end
        return @inactive_continent
    end

    #
    # Returns the room that characters start the game in for this continent, or `nil` if there isn't one.
    #
    # @return [Room, nil] The starting room, or `nil`.
    #
    def starting_room
        Game.instance.rooms.dig(@starting_room_id) || Game.instance.rooms.values.first
    end

    #
    # Returns the room that recall leads to on this continent, or `nil` if there isn't one.
    #
    # @return [Room, nil] The recall room, or `nil`.
    #
    def recall_room
        if @recall_room_id
            return Game.instance.rooms.dig(@recall_room_id) || nil
        end
        return nil
    end

end
