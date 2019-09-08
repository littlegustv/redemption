require_relative 'spell.rb'

class SpellAcidBlast < Spell

    def initialize
        super()
        @name = "acid blast"
        @keywords = ["acid", "blast", "acid blast"]
        @lag = 0.25
        @position = Position::STAND
    end

    def cast( actor, cmd, args )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on who, now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args )
    	if args.first.nil? && actor.attacking
    		actor.magic_hit( actor.attacking, 100, "acid blast", "corrosive" )
    	elsif ( target = actor.target({ not: actor, room: actor.room, type: ["Mobile", "Player"] }.merge( args.first.to_s.to_query )).first )
    		actor.magic_hit( target, 100, "acid blast", "corrosive" )
    	else
    		actor.output "They aren't here."
    	end
    end
end
