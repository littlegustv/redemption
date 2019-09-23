require_relative 'spell.rb'

class SpellLightningBolt < Spell

    def initialize(game)
        super(
            game: game,
            name: "lightning bolt",
            keywords: ["lightning bolt"],
            lag: 0.25,
            position: Position::STAND
        )
    end

    def cast( actor, cmd, args )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on who, now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args, level )
    	if args.first.nil? && actor.attacking
    		actor.magic_hit( actor.attacking, 100, "lightning bolt", "shocking" )
            return true
    	elsif ( target = actor.target({ room: actor.room, type: ["Mobile", "Player"] }.merge( args.first.to_s.to_query )).first )
    		actor.magic_hit( target, 100, "lightning bolt", "shocking" )
            return true
    	else
    		actor.output "They aren't here."
            return false
    	end
    end
end
