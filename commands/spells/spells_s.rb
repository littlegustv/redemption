require_relative 'spell.rb'

class SpellScramble < Spell

    def initialize
        super(
            name: "scramble",
            keywords: ["scramble"],
            lag: 0.25,
            position: Constants::Position::STAND,
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
            actor.output "There is no one here with that name."
            return false
        end
        target.apply_affect( AffectScramble.new( actor, target, actor.level ) )
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
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
    	if actor.room.affected? "shackle rune"
    		actor.output "This room is already affected by the restriction of movement."
            return false
    	else
    		actor.output "You place a shackle on the ground preventing easy movement."
    		actor.broadcast "%s places a strange rune on the ground.", actor.room.occupants - [actor], [actor]
    		actor.room.apply_affect( AffectShackleRune.new( actor, actor.room, actor.level ) )
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
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectShield.new( nil, actor, actor.level ) )
    end

end

class SpellShockingGrasp < Spell

    def initialize
        super(
            name: "shocking grasp",
            keywords: ["shocking grasp"],
            lag: 0.25,
            position: Constants::Position::STAND,
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.deal_damage(target: target, damage: 50, noun:"shocking grasp", element: Constants::Element::LIGHTNING, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellSleep < Spell

    def initialize
        super(
            name: "sleep",
            keywords: ["sleep"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            target.apply_affect( AffectSleep.new( nil, target, actor.level ) )
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
            position: Constants::Position::STAND,
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
        target.apply_affect( AffectSlow.new( actor, target, actor.level ) )
        target.start_combat( actor )
        return true
    end

end

class SpellStoneSkin < Spell

    def initialize
        super(
            name: "stoneskin",
            keywords: ["stone skin", "stoneskin"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectStoneSkin.new( nil, actor, actor.level ) )
    end

end

class SpellStun < Spell

    def initialize
        super(
            name: "stun",
            keywords: ["stun"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if args.first.nil? && actor.attacking
            target = actor.attacking
        else
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if target
            target.apply_affect( AffectStun.new( nil, target, actor.level ) )
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
            position: Constants::Position::STAND,
            mana_cost: 25
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if actor.can_see?(nil)
            target = actor.filter_visible_targets(Game.instance.target_global_mobiles(args.first.to_s.to_query).shuffle, 1).first
        end
        if target
            Game.instance.broadcast "%s disappears suddenly.", target.room.occupants - [target], [target]
            Game.instance.broadcast "%s arrives suddenly.", actor.room.occupants - [target], [target]
            target.move_to_room actor.room
            target.output "%s has summoned you!", [actor]
        else
            actor.output "You can't find anyone with that name."
        end
    end

end
