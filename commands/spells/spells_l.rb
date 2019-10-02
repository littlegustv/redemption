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
        target = nil
        if args.first.nil? && actor.attacking
            target = actor.attacking
        elsif !args.first.nil?
            target = actor.target({ list: actor.room.occupants }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.deal_damage(target: target, damage: 100, noun:"lightning bolt", element: Constants::Element::LIGHTNING, type: Constants::Damage::MAGICAL)
        return true
    end
end
