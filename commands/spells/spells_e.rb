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
        ( targets = actor.target( list: actor.room.occupants - [actor] ) ).each do |target|
            target.receive_damage(actor, 100, :earthquake)
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
        if ( target = actor.target( argument: args[0], list: actor.inventory.items, type: Armor ).first )
            fail = 25
            # dam =
            affect = AffectEnchantArmor.new( target, nil, actor.level )
            affect.overwrite_modifiers({ armor_class: -1 * level })
            affect.apply
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
        if ( target = actor.target( argument: args[0], list: actor.inventory.items, type: Weapon ).first )
            fail = 25
            # dam =
            affect = AffectEnchantWeapon.new( target, nil, actor.level )
            affect.overwrite_modifiers({hit_roll: level, damage_roll: 10})
            affect.apply
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
            target = actor.target( argument: args[0], list: actor.room.occupants ).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        target.receive_damage(actor, 100, :life_drain)
        target.use_movement( 10 )
        actor.regen( 0, 0, 10 )
        target.output "You feel your energy slipping away!"
        actor.output "Wow....what a rush!"
        return true
    end

end
