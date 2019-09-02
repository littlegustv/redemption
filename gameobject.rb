class GameObject

    attr_accessor :name, :keywords, :room

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
        query.to_a.all?{ |q| 
            @keywords.any?{ |keyword| 
                keyword.fuzzy_match( q )
            }
        }  
    end

    def can_see?
        true
    end

end
