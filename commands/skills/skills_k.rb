require_relative 'skill.rb'

class SkillKick < Command

    def initialize
        super()
        @name = "kick"
        @keywords = ["kick"]
        @lag = 1
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
        if args.length <= 0 and actor.attacking.nil?
            actor.output "Who did you want to kick?"
            return
        end
        if actor.position < Position::STAND
            actor.output "You have to stand up first."
        elsif actor.attacking and args.length <= 0
            do_kick( actor, actor.attacking )
        elsif ( kill_target = actor.target({ room: actor.room, not: actor, type: ["Mobile", "Player"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
            kill_target.start_combat actor
            actor.start_combat kill_target
            do_kick( actor, kill_target )
        else
            actor.output "I can't find anyone with that name."
        end
    end

    def do_bash( actor, target )
        target.hit 50, "kick", target
    end
end