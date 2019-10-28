require_relative 'skill.rb'

class SkillLair < Skill

    def initialize(game)
        super(
            game: game,
            name: "lair",
            keywords: ["lair"],
            lag: 0.25,
            position: Constants::Position::STAND,
        )
    end

    def attempt( actor, cmd, args, input )
        actor.room.apply_affect( AffectLair.new( source: actor, target: actor.room, level: actor.level, game: @game ) )
    end

end

class SkillLivingStone < Command

    def initialize(game)
        super(
            game: game,
            name: "living stone",
            keywords: ["living stone", "stone", "living"],
            lag: 1,
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args, input )
        if not actor.affected? "living stone"
            actor.apply_affect(AffectLivingStone.new(source: actor, target: actor, level: actor.level, game: @game))
            return true
        else
            actor.output "You did not manage to turn to stone."
            return false
        end
    end
end
