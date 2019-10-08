require_relative 'skill.rb'

class SkillKick < Command

    def initialize(game)
        super(
            game: game,
            name: "kick",
            keywords: ["kick"],
            lag: 1,
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        if args.length <= 0 and actor.attacking.nil?
            actor.output "Who did you want to kick?"
            return false
        end
        if actor.position < Constants::Position::STAND
            actor.output "You have to stand up first."
            return false
        elsif actor.attacking and args.length <= 0
            do_kick( actor, actor.attacking )
            return true
        elsif ( kill_target = actor.target({ list: actor.room.occupants, not: actor, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            do_kick( actor, kill_target )
            return true
        else
            actor.output "I can't find anyone with that name."
            return false
        end
    end

    def do_kick( actor, target )
        actor.deal_damage(target: target, damage: 50, noun:"kick", element: Constants::Element::BASH, type: Constants::Damage::PHYSICAL)
    end
end
