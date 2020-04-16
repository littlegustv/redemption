require_relative 'spell.rb'

class SpellEarthquake < Spell

    def initialize
        super(
            name: "earthquake",
            keywords: ["earthquake"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        (actor.room.area.occupants - [actor]).each_output "The earth trembles and shivers."
        actor.output "The earth trembles beneath your feet!"
        ( targets = actor.target({ not: actor, list: actor.room.occupants })).each do |target|
            actor.deal_damage(target, 100, "earthquake")
        end
        return true
    end
end

class SpellEnchantArmor < Spell

    def initialize
        super(
            name: "enchant armor",
            keywords: ["enchant armor", "enchant armour"],
            lag: 2,
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
            affect = AffectEnchantArmor.new( nil, target, actor.level )
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

    def initialize
        super(
            name: "enchant weapon",
            keywords: ["enchant weapon"],
            lag: 2,
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
            affect = AffectEnchantWeapon.new( nil, target, actor.level )
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

    def initialize
        super(
            name: "energy drain",
            keywords: ["energy drain"],
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
        actor.deal_damage(target, 100, "life drain")
        target.use_movement( 10 )
        actor.regen( 0, 0, 10 )
        target.output "You feel your energy slipping away!"
        actor.output "Wow....what a rush!"
        return true
    end

end
