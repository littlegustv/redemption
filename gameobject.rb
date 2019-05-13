class GameObject

    attr_accessor :name, :keywords

    def initialize( name, game )
        @name = name
        @keywords = [name]
        @game = game
    end

    def update( elapsed )
    end

    def output( message )
    end

    def broadcast( message, targets )
        @game.broadcast message, targets
    end

    def target( query )
        @game.target query
    end

    def to_a
        [ self ]
    end

    def to_s
        @name
    end

    def fuzzy_match( query )
        @keywords.select{ |keyword| keyword.fuzzy_match( query ) }.any?
    end

end
