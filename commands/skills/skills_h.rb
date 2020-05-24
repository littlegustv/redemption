require_relative 'skill.rb'

class SkillHide < Skill
    def initialize
        super(
            name: "hide",
            keywords: ["hide"],
            lag: 0.25,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        AffectHide.new( actor, nil, actor.level ).apply
    end
end
