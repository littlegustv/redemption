class Continent < GameObject

    attr_reader :id
    attr_reader :preposition
    attr_reader :areas

    def initialize( id, name, preposition, recall_room_id, starting_room_id )
        super(name, name.split(" "))
        @id = id
        @preposition = preposition
        @recall_room_id = recall_room_id
        @starting_room_id = starting_room_id
        @areas = []
    end

    def destroy
        super
        @areas.dup.each do |area|
            area.destroy
        end
        @areas = nil
        Game.instance.destroy_continent(self)
    end

    def self.inactive_continent
        if @inactive_continent.nil?
            @inactive_continent = Continent.new(0, "inactive continent", "on", 0, 0)
            @inactive_continent.deactivate
        end
        return @inactive_continent
    end

    def starting_room
        Game.instance.rooms.dig(@starting_room_id) || Game.instance.rooms.values.first
    end

    def recall_room
        Game.instance.rooms.dig(@recall_room_id) || Game.instance.rooms.values.first
    end

    def db_source_type_id
        return 6
    end

end
