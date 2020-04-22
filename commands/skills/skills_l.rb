require_relative 'skill.rb'

class SkillLair < Skill

    def initialize
        super(
            name: "lair",
            keywords: ["lair"],
            lag: 0.25,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        AffectLair.new( actor, actor.room, actor.level ).apply
    end

end

class SkillLivingStone < Command

    def initialize
        super(
            name: "living stone",
            keywords: ["living stone", "stone", "living"],
            lag: 1,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if not actor.affected? "living stone"
            AffectLivingStone.new( actor, actor, actor.level ).apply
            return true
        else
            actor.output "You did not manage to turn to stone."
            return false
        end
    end
end
