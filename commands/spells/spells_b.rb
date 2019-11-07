require_relative 'spell.rb'

class SpellBarkskin < Spell

    def initialize(game)
        super(
            game: game,
            name: "barkskin",
            keywords: ["barkskin", "bark skin"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectBarkSkin.new( nil, actor, actor.level, @game ) )
    end

end

class SpellBlastOfRot < Spell

    def initialize(game)
        super(
            game: game,
            name: "blast of rot",
            keywords: ["blast", "rot", "blast of rot"],
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
        actor.deal_damage(target: target, damage: 100, noun:"blast of rot", element: Constants::Element::POISON, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellBladeRune < Spell

    def initialize(game)
        super(
            game: game,
            name: "blade rune",
            keywords: ["blade rune"],
            lag: 0.25,
            position: Constants::Position::STAND
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
        if ( target = actor.target({ list: actor.items, item_type: "weapon", visible_to: actor }.merge( args.first.to_s.to_query )).first )
            if target.affected? "blade rune"
                actor.output "The existing blade rune repels your magic."
                return false
            else
                target.apply_affect( AffectBladeRune.new( actor, target, actor.level, @game ) )
                return true
            end
        else
            actor.output "You don't see that here."
            return false
        end
    end
end

class SpellBless < Spell

    def initialize(game)
        super(
            game: game,
            name: "bless",
            keywords: ["bless"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        if args.first.nil?
            actor.apply_affect( AffectBless.new( nil, actor, actor.level, @game ) )
        elsif ( target = @game.target({ list: actor.items + @room.occupants - [actor] }.merge( args.first.to_s.to_query )).first )
            target.apply_affect( AffectBless.new( nil, target, actor.level, @game ) )
        else
            actor.output "There is no one here with that name."
        end
    end

end

class SpellBlindness < Spell

    def initialize(game)
        super(
            game: game,
            name: "blindness",
            keywords: ["blindness"],
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
        target.apply_affect( AffectBlind.new( actor, target, actor.level, @game ) )
        target.start_combat( actor )
        return true
    end

end

class SpellBlink < Spell

    def initialize(game)
        super(
            game: game,
            name: "blink",
            keywords: ["blink"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        newroom = actor.room.area.rooms.sample
        @game.broadcast "%s blinks out of sight!", @game.target({ room: actor.room, not: actor }), [actor]
        actor.output "You blink out of sight!"
        actor.move_to_room newroom
    end

end

class SpellBlur < Spell

    def initialize(game)
        super(
            game: game,
            name: "blur",
            keywords: ["blur"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectBlur.new( nil, actor, actor.level, @game ) )
    end

end

class SpellBurningHands < Spell

    def initialize(game)
        super(
            game: game,
            name: "burning hands",
            keywords: ["burning hands"],
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
        actor.deal_damage(target: target, damage: 50, noun:"burning hands", element: Constants::Element::FIRE, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellBurstRune < Spell

    def initialize(game)
        super(
            game: game,
            name: "burst rune",
            keywords: ["burst rune"],
            lag: 0.25,
            position: Constants::Position::STAND
        )
    end

    def cast( actor, cmd, args, input )
        if args.first.nil?
            actor.output "Cast the spell on what now?"
            return
        else
            super
        end
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target({ list: actor.items, item_type: "weapon", visible_to: actor }.merge( args.first.to_s.to_query )).first )
            if target.affected? "burst rune"
                actor.output "The existing burst rune repels your magic."
                return false
            else
                target.apply_affect( AffectBurstRune.new( actor, target, level, @game ) )
                return true
            end
        else
            actor.output "You don't see that here."
            return false
        end
    end

end
