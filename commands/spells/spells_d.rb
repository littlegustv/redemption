require_relative 'spell.rb'

class SpellDestroyTattoo < Spell

    def initialize
        super()
        @name = "destroy tattoo"
        @keywords = ["destroy tattoo"]
        @lag = 0.25
        @position = Position::STAND
    end

    def cast( actor, cmd, args )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on what now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args )
    	if ( target = actor.target({ list: actor.equipment.values.reject(&:nil?), type: "tattoo" }.merge( args.first.to_s.to_query )).first )
    		actor.output "You focus your will and #{target} explodes into flames!"
    		target.destroy true
    	end
    end
end

class SpellDestroyRune < Spell

    def initialize
        super()
        @name = "destroy rune"
        @keywords = ["destroy rune"]
        @lag = 0.25
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
    	if args.first.nil?
    		if actor.room.affected? "rune"
                actor.room.remove_affect( "rune" )
                actor.broadcast "The runes present in this room begin fade.", actor.target({ room: actor.room })
            else
                actor.output "There are no runes found."
            end
    	elsif ( target = actor.target({ list: actor.equipment.values.reject(&:nil?) + actor.inventory, item_type: "weapon" }.merge( args.first.to_s.to_query )).first )
    		if target.affected?("rune")
    			actor.output "The runes on %s slowly fade out of existence.", [target]
    			target.remove_affect( "rune" )
            else
                actor.output "%s is not runed.", [target]
    		end
    	end
    end
end
