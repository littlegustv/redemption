require_relative 'skill.rb'

class SkillShadow < Skill

    def initialize
        super(
            name: "shadow",
            keywords: ["shadow"],
            lag: 0.25,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if args.first.nil?
            actor.remove_affects_with_keywords("follow")
        elsif ( target = actor.target( argument: args[0], list: actor.room.occupants - [actor] ).first )
            if actor.stat(:dexterity) >= target.stat(:intelligence)
                AffectFollow.new( actor, target, 1 ).apply(true)
                actor.output "You begin to secretly follow %n.", [target]
            else
                actor.output "Your attempt is painfully obvious."
                AffectFollow.new( actor, target, 1 ).apply
            end
        else
            actor.output "They aren't here"
        end
    end
end

class SkillSneak < Skill

    def initialize
        super(
            name: "sneak",
            keywords: ["sneak"],
            lag: 0,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        AffectSneak.new( actor, actor, actor.level ).apply
        return true
    end
end

class SkillSteal < Skill

    def initialize
        super(
            name: "steal",
            keywords: ["steal"],
            lag: 0.25,
            position: :standing,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input )
        if ( mobile_target = actor.target( argument: args[1], list: actor.room.occupants ).first )
            if ( item_target = actor.target( argument: args[0], list: mobile_target.inventory.items ).first )
                actor.output "You pocket 0<n>.", [ item_target ]
                actor.output "Got it!"
                item_target.move(actor.inventory)
                return true
            else
                actor.output "0<N> isn't carrying any '#{args[0]}'.", [mobile_target]
            end
        else
            actor.output "Steal from whom now?"
            return false
        end
    end
end
