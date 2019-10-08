require_relative 'skill.rb'

class SkillSneak < Command

    def initialize(game)
        super(
            game: game,
            name: "sneak",
            keywords: ["sneak"],
            lag: 0,
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        actor.apply_affect(AffectSneak.new(source: actor, target: actor, level: actor.level, game: @game))
        return true
    end
end
