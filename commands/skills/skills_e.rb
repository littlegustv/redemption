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
            aff = AffectPoisonWeapon.new( nil, target, actor.level )
            aff.duration = 300
	        aff.apply
        end
        return true
    end
end
