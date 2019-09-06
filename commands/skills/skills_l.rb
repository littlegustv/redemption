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
            actor.affects.push AffectLivingStone.new( actor, ["living stone"], 60, { damroll: 20, hitroll: 20, attack_speed: 3 }, 1 )
        else
            actor.output "You did not manage to turn to stone."
        end
    end
end