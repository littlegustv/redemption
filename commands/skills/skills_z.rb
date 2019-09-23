require_relative 'skill.rb'

class SkillZeal < Skill

    def initialize(game)
        super(
            game: game,
            name: "zeal",
            keywords: ["zeal"],
            lag: 0.1,
            position: Position::STAND
        )
    end

    def attempt( actor, cmd, args )
    	if not actor.affected? "zeal"
	        actor.apply_affect(AffectZeal.new( source: actor ))
            return true
	    else
	    	actor.remove_affect "zeal"
            return true
	    end
    end
end
