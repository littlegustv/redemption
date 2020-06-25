require_relative 'spell.rb'

class SpellScramble < Spell

    def initialize
        super(
            name: "scramble",
            keywords: ["scramble"],
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
            actor.output "There is no one here with that name."
            return false
        end
        AffectScramble.new( target, actor, actor.level ).apply
        target.start_combat( actor )
        return true
    end

end

class SpellShackleRune < Spell

    def initialize
        super(
            name: "shackle rune",
            keywords: ["shackle rune"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
    	if actor.room.affected? "shackle rune"
    		actor.output "This room is already affected by the restriction of movement."
            return false
    	else
    		actor.output "You place a shackle on the ground preventing easy movement."
            (actor.room.occupants - [actor]).each_output "0<N> places a strange rune on the ground.", [actor]
    		AffectShackleRune.new( actor.room, actor, actor.level ).apply
            return true
    	end
    end
end

class SpellShield < Spell


    def initialize
        super(
            name: "shield",
            keywords: ["shield", "shield"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        AffectShield.new( actor, nil, actor.level ).apply
    end

end

class SpellShockingGrasp < Spell

    def initialize
        super(
            name: "shocking grasp",
            keywords: ["shocking grasp"],
            lag: 0.25,
            mana_cost: 5
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
        target.receive_damage(actor, 50, :shocking_grasp)
        return true
    end
end

class SpellSleep < Spell

    def initialize
        super(
            name: "sleep",
            keywords: ["sleep"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target( argument: args[0], list: actor.room.occupants ).first )
            AffectSleep.new( target, nil, actor.level ).apply
        else
            actor.output "There is no one here with that name."
        end
    end

end

class SpellSlow < Spell

    def initialize
        super(
            name: "slow",
            keywords: ["slow"],
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
        AffectSlow.new( target, actor, actor.level ).apply
        target.start_combat( actor )
        return true
    end

end

class SpellStoneSkin < Spell

    def initialize
        super(
            name: "stone skin",
            keywords: ["stone skin", "stoneskin"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        AffectStoneSkin.new( actor, nil, actor.level ).apply
    end

end

class SpellStun < Spell

    def initialize
        super(
            name: "stun",
            keywords: ["stun"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if args.first.nil? && actor.attacking
            target = actor.attacking
        else
            target = actor.target( argument: args[0], list: actor.room.occupants ).first
        end
        if target
            target.output "Bands of force crush you, leaving you stunned momentarily."
            (target.room.occupants - [target]).each_output "Bands of force stun 0<n> momentarily.", [@target]
            AffectStun.new( target, nil, actor.level ).apply
            target.start_combat( actor )
            return true
        else
            actor.output "There is no one here with that name."
            return false
        end
    end

end

class SpellSummon < Spell

    def initialize
        super(
            name: "summon",
            keywords: ["summon"],
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
            (target.room.occupants - [target]).each_output "0<N> disappears suddenly.", [target]
            (target.room.occupants - [target]).each_output "0<N> arrives suddenly.", [target]
            target.move_to_room actor.room
            target.output "%N has summoned you!", [actor]
        else
            actor.output "You can't find anyone with that name."
        end
    end

end
