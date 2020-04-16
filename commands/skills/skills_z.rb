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
	        actor.apply_affect(AffectZeal.new( nil, actor, actor.level ))
            return true
	    else
	    	actor.remove_affect "zeal"
            return true
	    end
    end
end
