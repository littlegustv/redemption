require_relative 'skill.rb'

class SkillAnoint < Skill

    def initialize
        super(
            name: "anoint",
            keywords: ["anoint"],
            position: :standing,
            lag: 0.25
        )
    end

    def attempt( actor, cmd, args, input )
        AffectAnoint.new( actor, actor, actor.level ).apply
    end

end

class SkillAppraise < Skill

    def initialize
        super(
            name: "appraise",
            keywords: ["appraise"],
            position: :standing,
            lag: 0.25
        )
    end

    def attempt( actor, cmd, args, input )
        if args.length <= 0
            actor.output "What did you want to appraise?"
            return false
        end
        if (target = actor.target( argument: args[0], list: actor.items ).first )
            if target.affected? "appraised"
            	actor.output "%N has already been appraised.", [target]
            else
            	
            	target.cost *= 1.15
                actor.room.occupants.each_output "0<N> glitters and shines more brightly as 1<n> appraise1<,s> it.", [target, actor]
            end
            return true
        else
            actor.output("You can't find it.")
            return false
        end
    end
end
