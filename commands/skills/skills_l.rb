require_relative 'skill.rb'

class SkillLivingStone < Command

    def initialize
        super()
        @name = "living stone"
        @keywords = ["living stone", "stone", "living"]
        @lag = 1
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
        if not actor.affected? "living stone"
            actor.apply_affect(AffectLivingStone.new(source: actor, target: actor, level: actor.level))
        else
            actor.output "You did not manage to turn to stone."
        end
    end
end
