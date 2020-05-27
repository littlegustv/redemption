require_relative 'skill.rb'

class SkillZeal < Skill

    def initialize
        super(
            name: "zeal",
            keywords: ["zeal"],
            lag: 0.1,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
    	if not actor.affected? "zeal"
	        AffectZeal.new( actor, actor, actor.level ).apply
            return true
	    else
	    	actor.remove_affects_with_keywords "zeal"
            return true
	    end
    end
end
