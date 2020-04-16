require_relative 'skill.rb'

class SkillKick < Command

    def initialize
        super(
            name: "kick",
            keywords: ["kick"],
            lag: 1,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if args.length <= 0 and actor.attacking.nil?
            actor.output "Who did you want to kick?"
            return false
        end
        if actor.attacking and args.length <= 0
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
        actor.deal_damage(target, 50, "kick")
    end
end
