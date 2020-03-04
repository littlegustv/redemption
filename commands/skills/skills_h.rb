require_relative 'skill.rb'

class SkillHide < Skill
    def initialize
        super(
            name: "hide",
            keywords: ["hide"],
            lag: 0.25,
            position: Constants::Position::STAND,
        )
    end

    def attempt( actor, cmd, args, input )
        actor.apply_affect( AffectHide.new( nil, actor, actor.level ) )
    end
end
