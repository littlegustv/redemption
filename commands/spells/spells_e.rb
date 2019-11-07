require_relative 'spell.rb'

class SpellEarthquake < Spell

    def initialize(game)
        super(
            game: game,
            name: "earthquake",
            keywords: ["earthquake"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.broadcast "%s makes the earth tremble and shiver.", actor.room.area.occupants - [actor], [actor]
        actor.output "The earth trembles beneath your feet!"
        ( targets = actor.target({ not: actor, list: actor.room.occupants })).each do |target|
            actor.deal_damage(target: target, damage: 100, noun:"earthquake", element: Constants::Element::GEOLOGY, type: Constants::Damage::MAGICAL)
        end
        return true
    end
end

class SpellEnchantArmor < Spell

    def initialize(game)
        super(
            game: game,
            name: "enchant armor",
            keywords: ["enchant armor", "enchant armour"],
            lag: 2,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def cast( actor, cmd, args, input )
        if args.first.nil?
            actor.output "Cast the spell on what now?"
        else
            super
        end
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target({ list: actor.inventory.items, item_type: "armor" }.merge( args.first.to_s.to_query )).first )
            fail = 25
            # dam =
            affect = AffectEnchantArmor.new( nil, target, actor.level, @game )
            affect.overwrite_modifiers({ ac_pierce: -1 * level, ac_slash: -1 * level, ac_bash: -1 * level, ac_magic: -1 * level })
            target.apply_affect( affect )
            return true
        else
            actor.output "You don't see that here."
            return false
        end
    end
end

class SpellEnchantWeapon < Spell

    def initialize(game)
        super(
            game: game,
            name: "enchant weapon",
            keywords: ["enchant weapon"],
            lag: 2,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def cast( actor, cmd, args, input )
    	if args.first.nil?
    		actor.output "Cast the spell on what now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target({ list: actor.inventory.items, item_type: "weapon" }.merge( args.first.to_s.to_query )).first )
            fail = 25
            # dam =
            affect = AffectEnchantWeapon.new( nil, target, actor.level, @game )
            affect.overwrite_modifiers({hitroll: level, damroll: 10})
            target.apply_affect( affect )
            return true
        else
            actor.output "You don't see that here."
            return false
        end
    end
end

class SpellEnergyDrain < Spell

    def initialize(game)
        super(
            game: game,
            name: "energy drain",
            keywords: ["energy drain"],
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
        target = nil
        if args.first.nil? && actor.attacking
            target = actor.attacking
        elsif !args.first.nil?
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.deal_damage(target: target, damage: 100, noun:"life drain", element: Constants::Element::NEGATIVE, type: Constants::Damage::MAGICAL)
        target.use_movement( 10 )
        actor.regen( 0, 0, 10 )
        target.output "You feel your energy slipping away!"
        actor.output "Wow....what a rush!"
        return true
    end

end
