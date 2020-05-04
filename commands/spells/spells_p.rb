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
        AffectPassDoor.new( nil, actor, actor.level ).apply
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
        AffectFollow.new( actor, mob, 1 ).apply
        AffectCharm.new( actor, mob, actor.level ).apply
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.deal_damage(target, 100, "ghoulish grasp")
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        AffectPlague.new( actor, target, actor.level ).apply
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        AffectPoisoned.new( actor, target, actor.level ).apply
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
            # remove auto-added affect
            portal.remove_affect("portal")
            AffectPortal.new( portal, target.room ).apply

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
            AffectProtectionGood.new( nil, actor, actor.level ).apply
        elsif args.first.to_s.fuzzy_match("neutral")
            AffectProtectionNeutral.new( nil, actor, actor.level ).apply
        elsif args.first.to_s.fuzzy_match("evil")
            AffectProtectionEvil.new( nil, actor, actor.level ).apply
        end
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.deal_damage(target, 100, "pyrotechnics")
        return true
    end
end
