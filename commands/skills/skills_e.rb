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
        if ( target = actor.target( argument: args[0], list: actor.items, type: Weapon ).first )
            if target.affected?("poison")
                actor.output "That's already poisoned."
                return false
            end
            aff = AffectPoisonWeapon.new( target, nil, actor.level )
            aff.set_duration(300)
            aff.apply
        else
            actor.output "You don't see that here."
            return false
        end
        return true
    end
end
