require_relative 'spell.rb'

class SpellPassDoor < Spell

    def initialize
        super(
            name: "pass door",
            keywords: ["pass door"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        AffectPassDoor.new( actor, nil, actor.level ).apply
    end

end

class SpellPhantasmMonster < Spell

    def initialize
        super(
            name: "phantasm monster",
            keywords: ["phantasm monster"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.output "You call forth phantasmic forces!"
        mob = Game.instance.load_mob( 1844, actor.room )
        AffectFollow.new( mob, actor, 1 ).apply
        AffectCharm.new( mob, actor, actor.level ).apply
    end

end

class SpellPhantomForce < Spell

    def initialize
        super(
            name: "phantom force",
            keywords: ["phantom force"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args, input )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
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
        target.receive_damage(actor, 100, :ghoulish_grasp)
        return true
    end
end

class SpellPlague < Spell

    def initialize
        super(
            name: "plague",
            keywords: ["plague"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args, input )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
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
        AffectPlague.new( target, actor, actor.level ).apply
        target.start_combat( actor )
        return true
    end

end

class SpellPoison < Spell

    def initialize
        super(
            name: "poison",
            keywords: ["poison"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args, input )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
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
        AffectPoisoned.new( target, actor, actor.level ).apply
        target.start_combat( actor )
        return true
    end
end

class SpellPortal < Spell

    def initialize
        super(
            name: "portal",
            keywords: ["portal"],
            lag: 0.25,
            mana_cost: 25
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if actor.can_see?(nil)
            target = actor.filter_visible_targets(Game.instance.target_global_mobiles(args.first.to_s.to_query).shuffle, 1).first
        end
        if target
            portal = Game.instance.load_item( 1956, actor.room.inventory )
            portal.set_destination(target.room)

            actor.output "0<N> rises up before you.", [portal]
            (actor.room.occupants - [actor]).each_output "%N rises up from the ground.", [portal]
        else
            actor.output "You can't find anyone with that name."
        end
    end

end

class SpellProtection < Spell

    def initialize
        super(
            name: "protection",
            keywords: ["protection"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if args.first.to_s.fuzzy_match("good")
            AffectProtectionGood.new( actor, nil, actor.level ).apply
        elsif args.first.to_s.fuzzy_match("neutral")
            AffectProtectionNeutral.new( actor, nil, actor.level ).apply
        elsif args.first.to_s.fuzzy_match("evil")
            AffectProtectionEvil.new( actor, nil, actor.level ).apply
        end
    end

end

class SpellPurification < Spell

    def initialize
        super(
            name: "purification",
            keywords: ["purification"],
            lag: 0.25,
        )
    end

    def cast( actor, cmd, args, input )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
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

        old_hp = target.health
        target.regen( 20 + level, 0, 0 )
        healed = target.health - old_hp

        log("Healed #{healed}, #{old_hp} #{target.health}")

        target.target( list: target.room.occupants, attacking: target ).each do |splash_victim|
            splash_victim.receive_damage( actor, healed, :divine_power )
        end
        return true
    end
end

class SpellPyrotechnics < Spell

    def initialize
        super(
            name: "pyrotechnics",
            keywords: ["pyrotechnics"],
            lag: 0.25,
        )
    end

    def cast( actor, cmd, args, input )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on who, now?"
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
        target.receive_damage(actor, 100, :pyrotechnics)
        return true
    end
end
