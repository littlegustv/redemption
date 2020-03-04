require_relative 'spell.rb'

class SpellVentriloquate < Spell

    def initialize
        super(
            name: "ventriloquate",
            keywords: ["ventriloquate"],
            lag: 0.25,
            position: Constants::Position::STAND,
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
    	if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
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
