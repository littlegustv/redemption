require_relative 'spell.rb'

class SpellDestroyTattoo < Spell

    def initialize(game)
        super(
            game: game,
            name: "destroy tattoo",
            keywords: ["destroy tattoo"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on what now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args, level )
    	if ( target = actor.target({ list: actor.equipment, type: "tattoo" }.merge( args.first.to_s.to_query )).first )
    		actor.output "You focus your will and #{target} explodes into flames!"
    		target.destroy true
            return true
        else
            actor.output "You don't have a tattoo like that."
            return false
    	end
    end
end

class SpellDestroyRune < Spell

    def initialize(game)
        super(
            game: game,
            name: "destroy rune",
            keywords: ["destroy rune"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, level )
    	if args.first.nil?
    		if actor.room.affected? "rune"
                actor.room.remove_affect( "rune" )
                actor.broadcast "The runes present in this room begin fade.", actor.target({ room: actor.room })
                return true
            else
                actor.output "There are no runes found."
                return false
            end
    	elsif ( target = actor.target({ list: actor.equipment + actor.inventory, item_type: "weapon" }.merge( args.first.to_s.to_query )).first )
    		if target.affected?("rune")
    			actor.output "The runes on %s slowly fade out of existence.", [target]
    			target.remove_affect( "rune" )
                return true
            else
                actor.output "%s is not runed.", [target]
                return false
    		end
    	end
    end
end
