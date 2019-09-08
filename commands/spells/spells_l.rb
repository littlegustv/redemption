require_relative 'spell.rb'

class SpellLightningBolt < Spell

    def initialize
        super()
        @name = "lightning bolt"
        @keywords = ["lightning", "bolt", "lightning bolt"]
        @lag = 0.25
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
    	if ( target = actor.target({ not: actor, room: actor.room, type: ["Mobile", "Player"] }.merge( args.first.to_s.to_query )).first )
    		actor.magic_hit( target, 100, "lightning bolt", "shocking" )
    	else
    		actor.output "They aren't here."
    	end
    end
end
