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

    def cast( actor, cmd, args )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on what now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args )
    	if args.first.nil?
    		# in-room affects
    	elsif ( target = actor.target({ list: actor.equipment.values.reject(&:nil?) + actor.inventory, item_type: "weapon" }.merge( args.first.to_s.to_query )).first )
    		if target.affected?("burst rune") || target.affected?("blade_rune")
    			actor.output "The runes on %s slowly fade out of existence.", [target]
    			target.remove_affect( "burst rune" )
    			target.remove_affect( "blade rune" )
    		end
    	end
    end
end
