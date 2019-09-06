class Continent < GameObject

    attr_reader :preposition, :starting_room_id, :recall_room_id

    def initialize( data, game )
        @id = data[:id]
        @preposition = data[:preposition]
        @name = data[:name]
        @starting_room_id = data[:starting_room_id]
        @recall_room_id = data[:recall_room_id]
        super name, game
    end

end
