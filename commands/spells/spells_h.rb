require_relative 'spell.rb'

class SpellHurricane < Spell

    def initialize
        super()
        @name = "hurricane"
        @keywords = ["hurricane"]
        @lag = 0.4
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
    end
end
