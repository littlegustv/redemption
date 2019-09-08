require_relative 'spell.rb'

class SpellHurricane < Spell

    def initialize
        super()
        @name = "hurricane"
        @keywords = ["hurricane"]
        @lag = 0.25
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
    	( targets = actor.target({ not: actor, quantity: "all", room: actor.room, type: ["Mobile", "Player"] })).each do |target|
    		actor.magic_hit( target, 100, "hurricane", "flooding" )
    	end
    end
end
