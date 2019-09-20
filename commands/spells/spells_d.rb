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

    def attempt( actor, cmd, args )
    	if ( target = actor.target({ list: actor.equipment.values.reject(&:nil?), type: "tattoo" }.merge( args.first.to_s.to_query )).first )
    		actor.output "You focus your will and #{target} explodes into flames!"
    		target.destroy true
    	end
    end
end
