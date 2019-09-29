class Continent < GameObject

    attr_reader :id
    attr_reader :preposition
    attr_reader :recall_room_id
    attr_reader :starting_room_id

    def initialize( data, game )
        super(data[:name], game)
        @id = data[:id]
        @preposition = data[:preposition]
        @recall_room_id = data[:recall_room_id]
        @starting_room_id = data[:starting_room_id]
    end

    # alias for @game.destroy_continent(self)
    def destroy
        @game.destroy_continent(self)
    end

end
