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
        actor.apply_affect(AffectSneak.new(source: actor, target: actor, level: actor.level))
    end
end
