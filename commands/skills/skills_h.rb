require_relative 'skill.rb'

class SkillHide < Skill
    def initialize(game)
        super(
            game: game,
            name: "hide",
            keywords: ["hide"],
            lag: 0.25,
            position: Constants::Position::STAND,
        )
    end

    def attempt( actor, cmd, args, input )
        actor.apply_affect( AffectHide.new( source: nil, target: actor, level: actor.level, game: @game ) )
    end
end
