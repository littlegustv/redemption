require_relative 'spell.rb'

class SpellCalm < Spell

    def initialize(game)
        super(
            game: game,
            name: "calm",
            keywords: ["calm"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.room.occupants.each do | entity |
            entity.output "A wave of calm washes over you."
            @game.broadcast "%s calms down and loses the will to fight.", entity.room.occupants - [entity], [entity]
            entity.remove_affect "berserk"
            entity.remove_affect "frenzy"
            entity.remove_affect "taunt"
            entity.stop_combat
            entity.apply_affect( AffectCalm.new( source: nil, target: entity, level: actor.level, game: @game ) )
        end
    end

end

class SpellCancellation < Spell

    def initialize(game)
        super(
            game: game,
            name: "cancellation",
            keywords: ["cancellation"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.remove_affect( actor.affects.sample.keywords.first ) if actor.affects.count > 0
    end

end

class SpellCauseLight < Spell

    def initialize(game)
        super(
            game: game,
            name: "cause light",
            keywords: ["cause light"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
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
        actor.deal_damage(target: target, damage: 25, noun:"cause light wounds", element: Constants::Element::HOLY, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellCauseSerious < Spell

    def initialize(game)
        super(
            game: game,
            name: "cause serious",
            keywords: ["cause serious"],
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
        actor.deal_damage(target: target, damage: 50, noun:"cause serious wounds", element: Constants::Element::HOLY, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellCauseCritical < Spell

    def initialize(game)
        super(
            game: game,
            name: "cause critical",
            keywords: ["cause critical"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 25
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
        actor.deal_damage(target: target, damage: 75, noun:"cause critical wounds", element: Constants::Element::HOLY, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellChainLightning < Spell

    def initialize(game)
        super(
            game: game,
            name: "chain lightning",
            keywords: ["chain lightning"],
            lag: 0.5,
            position: Constants::Position::STAND,
            mana_cost: 50
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
            target = actor.target({ list: actor.room.occupants }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        @game.broadcast "A lightning bolt leaps from %s's hand and arcs to %s.", actor.room.occupants - [actor, target], [actor, target]
        actor.output "A lightning bolt leaps from your hand and arcs to %s.", [target]
        target.output "A lightning bolt leaps from %s's hand and strikes you!", [actor]

        damage = 100
        actor.deal_damage(target: target, damage: damage, noun:"lightning bolt", element: Constants::Element::LIGHTNING, type: Constants::Damage::MAGICAL)
        while (damage -= 10) >= 0
            target = actor.room.occupants.sample

            if target == actor
                @game.broadcast "The bolt arcs to %s...whoops!", actor.room.occupants - [target], [actor, target]
                target.output "You are struck by your own lightning!"
            else
                @game.broadcast "The bolt arcs to %s!", actor.room.occupants - [target], [target]
                target.output "The bolt arcs to you!"
            end

            actor.deal_damage(target: target, damage: damage, noun:"lightning bolt", element: Constants::Element::LIGHTNING, type: Constants::Damage::MAGICAL)
        end

        @game.broadcast "The bolt seems to have fizzled out.", actor.room.occupants - [target]
        target.output "The bolt grounds out through your body."

        return true
    end
end

class SpellCharmPerson < Spell

    def initialize(game)
        super(
            game: game,
            name: "charm person",
            keywords: ["charm person"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = @game.target( { list: actor.room.occupants - [actor], visible_to: actor }.merge( args.first.to_s.to_query ) ).first )
            if rand(1..10) <= 5
                actor.output "%s looks at you with adoring eyes.", [target]
                target.output "Isn't %s just so nice??", [actor]
                target.apply_affect( AffectFollow.new( source: actor, target: target, level: 1, game: @game ) )
                target.apply_affect( AffectCharm.new( source: actor, target: target, level: actor.level, game: @game ) )
            else
                actor.output "You failed."
                target.start_combat( actor )
            end
        else
            actor.output "There is no one here with that name."
        end
    end

end

class SpellCloakOfMind < Spell

    def initialize(game)
        super(
            game: game,
            name: "cloak of mind",
            keywords: ["cloak of mind"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectCloakOfMind.new( source: nil, target: actor, level: actor.level, game: @game ) )
    end

end

class SpellCloudkill < Spell

    def initialize(game)
        super(
            game: game,
            name: "cloudkill",
            keywords: ["cloudkill"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.room.apply_affect( AffectCloudkill.new( source: actor, target: actor.room, level: actor.level, game: @game ) )
    end

end

class SpellColorSpray < Spell

    def initialize(game)
        super(
            game: game,
            name: "colour spray",
            keywords: ["color spray", "colour spray"],
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
        actor.deal_damage(target: target, damage: 50, noun:"color spray", element: Constants::Element::LIGHT, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellContinualLight < Spell

    def initialize(game)
        super(
            game: game,
            name: "continual light",
            keywords: ["continual light"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        if args.first.nil?
            item = @game.load_item( 1952, actor.inventory )
            actor.broadcast "%s twiddles their thumbs and %s appears.", actor.room.occupants - [actor], [actor, item]
            actor.output "You twiddle your thumbs and %s appears.", [item]
        elsif ( target = @game.target( { list: actor.items + actor.room.items, visible_to: actor }.merge( args.first.to_s.to_query ) ).first )
            target.apply_affect( AffectGlowing.new( source: nil, target: target, level: actor.level, game: @game ))
        else
            actor.output "You don't see that here."
        end
    end
end

class SpellCureBlindness < Spell

    def initialize(game)
        super(
            game: game,
            name: "cure blindness",
            keywords: ["cure blindness"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 14
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = args.first.nil? ? actor : actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        if target 
            if target.affected? "blind"
                target.output "Your vision returns!"
                target.remove_affect "blind"
            else
                actor.output "They aren't blind."
            end
        else
            actor.output "They aren't here."
        end
    end
end

class SpellCureCritical < Spell

    def initialize(game)
        super(
            game: game,
            name: "cure critical",
            keywords: ["cure critical"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 12
        )
    end

    def attempt( actor, cmd, args, input, level )
        quantity = 50
        if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            target.output "You feel better!"
            target.regen( quantity, 0, 0 )
        elsif args.first.nil?
            actor.output "You feel better"
            actor.regen( quantity, 0, 0 )
        else
            actor.output "They aren't here."
        end
    end
end

class SpellCureDisease < Spell

    def initialize(game)
        super(
            game: game,
            name: "cure disease",
            keywords: ["cure disease"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 15
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = args.first.nil? ? actor : actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        if target 
            if target.affected? "plague"
                target.output "You feel better!"
                target.remove_affect "plague"
            else
                actor.output "They aren't infected."
            end
        else
            actor.output "They aren't here."
        end
    end
end

class SpellCureLight < Spell

    def initialize(game)
        super(
            game: game,
            name: "cure light",
            keywords: ["cure light"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        quantity = 10
        if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            target.output "You feel better!"
            target.regen( quantity, 0, 0 )
        elsif args.first.nil?
            actor.output "You feel better"
            actor.regen( quantity, 0, 0 )
        else
            actor.output "They aren't here."
        end
    end
end

class SpellCurePoison < Spell

    def initialize(game)
        super(
            game: game,
            name: "cure poison",
            keywords: ["cure poison"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 14
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = args.first.nil? ? actor : actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        if target 
            if target.affected? "poison"
                target.output "You feel better!"
                target.remove_affect "poison"
            else
                actor.output "They aren't poisoned."
            end
        else
            actor.output "They aren't here."
        end
    end
end

class SpellCureSerious < Spell

    def initialize(game)
        super(
            game: game,
            name: "cure serious",
            keywords: ["cure serious"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 11
        )
    end

    def attempt( actor, cmd, args, input, level )
        quantity = 25
        if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            target.output "You feel better!"
            target.regen( quantity, 0, 0 )
        elsif args.first.nil?
            actor.output "You feel better"
            actor.regen( quantity, 0, 0 )
        else
            actor.output "They aren't here."
        end
    end
end

class SpellCurse < Spell

    def initialize(game)
        super(
            game: game,
            name: "curse",
            keywords: ["curse"],
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
        target.apply_affect( AffectCurse.new( source: actor, target: target, level: actor.level, game: @game ) )
        target.start_combat( actor )
        return true
    end

end