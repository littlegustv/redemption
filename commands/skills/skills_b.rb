require_relative 'skill.rb'

class SkillBash < Skill

    def initialize(game)
        super(
            game: game,
            name: "bash",
            keywords: ["bash"],
            lag: 2,
            position: Position::STAND
        )
        @data[:target_lag] = 0.5
    end

    def attempt( actor, cmd, args )
        target = nil
        if args.length > 0
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        else
            target = actor.attacking
        end
        if target.nil?
            actor.output "Who did you want to bash?"
            return false
        end
        if target == actor
            actor.output "You fall flat on your face!"
            return true
        end
        if actor.position < Position::STAND
            actor.output "You have to stand up first."
            return false
        end
        do_bash( actor, target )
        return true
    end

    def do_bash( actor, target )
        actor.output "You slam into %s, and send him flying!", [target]
        target.output "%s sends you flying with a powerful bash!", [actor]
        actor.broadcast "%s sends %s flying with a powerful bash!", actor.target({ not: [ actor, target ], list: actor.room.occupants }), [actor, target]
        actor.deal_damage(target: target, damage: 100, noun:"bash", element: Constants::Element::BASH, type: Constants::Damage::PHYSICAL)
        puts @data[:target_lag]
        target.lag += @data[:target_lag]
    end
end

class SkillBerserk < Skill

    def initialize(game)
        super(
            game: game,
            name: "berserk",
            keywords: ["berserk"],
            lag: 0.5,
            position: Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        if not actor.affected? "berserk"
            actor.apply_affect(AffectBerserk.new(source: actor, target: actor, level: actor.level, game: @game))
            return true
        else
            actor.output "You are already pretty mad."
            return false
        end
    end
end
