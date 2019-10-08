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

    def cast( actor, cmd, args )
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