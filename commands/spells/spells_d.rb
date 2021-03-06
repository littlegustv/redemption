require_relative 'spell.rb'

class SpellDarkness < Spell

    def initialize
        super(
            name: "darkness",
            keywords: ["darkness"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        AffectDarkness.new( actor.room, actor, level ).apply
    end

end

class SpellDeathRune < Spell

    def initialize
        super(
            name: "death rune",
            keywords: ["death rune"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        AffectDeathRune.new( actor, actor, level ).apply
    end

end

class SpellDemonFire < Spell

    def initialize
        super(
            name: "demonfire",
            keywords: ["demonfire"],
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
        if actor.alignment > -100
            target = actor
        elsif args.first.nil? && actor.attacking
            target = actor.attacking
        elsif !args.first.nil?
            target = actor.target( argument: args[0], list: actor.room.occupants ).first
        end

        if !target
            actor.output "They aren't here."
            return false
        end

        if target == actor
            actor.output "The demons turn upon you!"
        else
            actor.output "You conjure forth the demons of hell!"
            target.output "0<N> has assailed you with the demons of Hell!", [actor]
        end

        (actor.room.occupants - [target, actor]).each_output "0<N> calls forth the demons of Hell upon 1<n>!", [actor, target]

        target.receive_damage(actor, 100, :torments)
        actor.alignment = [ actor.alignment - 50, -1000 ].max

        AffectCurse.new( target, nil, actor.level ).apply

        return true
    end
end

class SpellDestroyRune < Spell

    def initialize
        super(
            name: "destroy rune",
            keywords: ["destroy rune"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
    	if args.first.nil?
    		if actor.room.affected? "rune"
                actor.room.occupants.each_output "The runes present in this room begin fade."
                actor.room.remove_affects_with_keywords( "rune" )
                return true
            else
                actor.output "There are no runes found."
                return false
            end
    	elsif ( target = actor.target( argument: args[0], list: actor.items, type: Weapon ).first )
    		if target.affected?("rune")
    			actor.output "The runes on 0<n> slowly fade out of existence.", [target]
    			target.remove_affects_with_keywords( "rune" )
                return true
            else
                actor.output "0<N> is not runed.", [target]
                return false
    		end
    	end
    end
end

class SpellDestroyTattoo < Spell

    def initialize
        super(
            name: "destroy tattoo",
            keywords: ["destroy tattoo"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args, input )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on what now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args, input, level )
    	if ( target = actor.target( argument: args[0], list: actor.equipment, type: Tattoo ).first )
    		actor.output "You focus your will and 0<n> explodes into flames!", [target]
    		target.destroy true
            return true
        else
            actor.output "You don't have a tattoo like that."
            return false
    	end
    end
end

class SpellDetectInvisibility < Spell

    def initialize
        super(
            name: "detect invisibility",
            keywords: ["detect invisibility"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        AffectDetectInvisibility.new( actor, actor, level ).apply
    end

end

class SpellDetectMagic < Spell

    def initialize
        super(
            name: "detect magic",
            keywords: ["detect magic"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target( argument: args[0], list: actor.room.occupants ).first )
            actor.output target.show_affects(actor)
            return true
        else
            actor.output "There is no one here with that name."
            return false
        end
    end
end

class SpellDispelMagic < Spell

    def initialize
        super(
            name: "dispel magic",
            keywords: ["dispel magic"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target( argument: args[0], list: actor.room.occupants ).first )
            target.remove_affects_with_keywords( actor.affects.sample.keywords.first ) if target.affects && target.affects.count > 0
            return true
        else
            actor.output "There is no one here with that name."
            return false
        end
    end

end
