require_relative 'skill.rb'

class SkillEnvenom < Skill

    def initialize
        super(
            name: "envenom",
            keywords: ["envenom"],
            lag: 0.25,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = Game.instance.target({ list: actor.items, item_type: "weapon", visible_to: actor }.merge( args.first.to_s.to_query ) ).first )
	        AffectPoison.new( nil, target, actor.level ).apply
        end
        return true
    end
end
