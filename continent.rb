class Continent < GameObject

    attr_reader :id
    attr_reader :preposition
    attr_reader :recall_room_id
    attr_reader :starting_room_id
    attr_reader :areas

    def initialize( data )
        super(data[:name], data[:name].split(" "))
        @id = data[:id]
        @preposition = data[:preposition]
        @recall_room_id = data[:recall_room_id]
        @starting_room_id = data[:starting_room_id]
        @areas = []
    end

    def destroy
        super
        @areas.each do |area|
            area.destroy
        end
        Game.instance.destroy_continent(self)
    end

    def db_source_type
        return "Continent"
    end

end
