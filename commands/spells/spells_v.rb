require_relative 'spell.rb'

class SpellVentriloquate < Spell

    def initialize
        super(
            name: "ventriloquate",
            keywords: ["ventriloquate"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args, input )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on who, now?"
            return
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args, input, level )
    	if ( target = actor.target( argument: args[0], list: actor.room.occupants ).first )
            words = input.split(" ")
            message = input[/#{words[1]}.*#{words[2]} (.*)/, 1]
    		target.do_command "say #{message}"
            return true
    	else
    		actor.output "They aren't here."
            return false
    	end
    end
end
