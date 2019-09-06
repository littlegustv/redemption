require_relative 'skill.rb'

class SkillSneak < Command

    def initialize
        super()
        @name = "sneak"
        @keywords = ["sneak"]
        @lag = 0
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
        if not actor.affected? "sneak"
            actor.affects.push AffectSneak.new( actor, ["sneak"], 60, { none: 0 }, 1 )
        else
            actor.output "You fail to move silently."
        end
    end
end