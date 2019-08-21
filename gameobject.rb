class GameObject

    attr_accessor :name, :keywords

    def initialize( name, game )
        @name = name
        @keywords = [name]
        @game = game
    end

    def update( elapsed )
    end

    def output( message, objects = [] )
    end

    def broadcast( message, targets, objects = [] )
        @game.broadcast message, targets, objects
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

    def to_someone
        "someone"
    end

    def show( looker )
        if looker.can_see? self
            to_s
        else
            to_someone
        end
    end

    def fuzzy_match( query )
        count = query.match( /\A(\d+)\./ )
        @keywords.select{ |keyword| keyword.fuzzy_match( query ) }.any?
    end

    def can_see?
        true
    end

end
