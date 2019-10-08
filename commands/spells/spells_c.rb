require_relative 'spell.rb'

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

    def cast( actor, cmd, args )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
        else
            super
        end
    end

    def attempt( actor, cmd, args, level )
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

    def cast( actor, cmd, args )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
        else
            super
        end
    end

    def attempt( actor, cmd, args, level )
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

    def cast( actor, cmd, args )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
        else
            super
        end
    end

    def attempt( actor, cmd, args, level )
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

class SpellHarm < Spell

    def initialize(game)
        super(
            game: game,
            name: "harm",
            keywords: ["harm"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 50
        )
    end

    def cast( actor, cmd, args )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
        else
            super
        end
    end

    def attempt( actor, cmd, args, level )
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
        actor.deal_damage(target: target, damage: 100, noun:"harm", element: Constants::Element::HOLY, type: Constants::Damage::MAGICAL)
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

    def cast( actor, cmd, args )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
        else
            super
        end
    end

    def attempt( actor, cmd, args, level )
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
        @game.broadcast "A lightning bolt leaps from %s's hand and arcs to %s.", @game.target({ list: actor.room.occupants, not: [actor, target] }), [actor, target]
        actor.output "A lightning bolt leaps from your hand and arcs to %s.", [target]
        target.output "A lightning bolt leaps from %s's hand and strikes you!", [actor]

        damage = 100
        actor.deal_damage(target: target, damage: damage, noun:"lightning bolt", element: Constants::Element::LIGHTNING, type: Constants::Damage::MAGICAL)
        while (damage -= 10) >= 0            
            target = actor.room.occupants.sample
        
            if target == actor
                @game.broadcast "The bolt arcs to %s...whoops!", @game.target({ list: actor.room.occupants, not: [target] }), [actor, target]
                target.output "You are struck by your own lightning!"
            else
                @game.broadcast "The bolt arcs to %s!", @game.target({ list: actor.room.occupants, not: [target] }), [target]
                target.output "The bolt arcs to you!"
            end

            actor.deal_damage(target: target, damage: damage, noun:"lightning bolt", element: Constants::Element::LIGHTNING, type: Constants::Damage::MAGICAL)
        end

        @game.broadcast "The bolt seems to have fizzled out.", @game.target({ list: actor.room.occupants, not: [target] })
        target.output "The bolt grounds out through your body."

        return true
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

class SpellColorSpray < Spell

    def initialize(game)
        super(
            game: game,
            name: "color spray",
            keywords: ["color spray", "colour spray"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def cast( actor, cmd, args )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
            return
        else
            super
        end
    end

    def attempt( actor, cmd, args, level )
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