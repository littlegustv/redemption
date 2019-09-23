require_relative 'spell.rb'

class SpellEnchantWeapon < Spell

    def initialize(game)
        super(
            game: game,
            name: "enchant weapon",
            keywords: ["enchant weapon"],
            lag: 2,
            position: Position::STAND,
            mana_cost: 5
        )
    end

    def cast( actor, cmd, args )
    	if args.first.nil?
    		actor.output "Cast the spell on what now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args, level )
        if ( target = actor.target({ list: actor.inventory, item_type: "weapon" }.merge( args.first.to_s.to_query )).first )
            fail = 25
            # dam =
            affect = AffectEnchantWeapon.new( source: nil, target: target, level: actor.level, game: @game )
            affect.overwrite_modifiers({hitroll: level, damroll: 10})
            target.apply_affect( affect )
            return true
        else
            actor.output "You don't see that here."
            return false
        end
    end
end
