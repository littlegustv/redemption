require_relative 'spell.rb'

class SpellVentriloquate < Spell

    def initialize(game)
        super(
            game: game,
            name: "ventriloquate",
            keywords: ["ventriloquate"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on who, now?"
            return
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args, level )
    	if args.first.nil? && actor.attacking
    		actor.attacking.do_command "say #{args[1..-1].to_a.join(' ')}"
            return true
    	elsif ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
    		target.do_command "say #{args[1..-1].to_a.join(' ')}"
            return true
    	else
    		actor.output "They aren't here."
            return false
    	end
    end
end
