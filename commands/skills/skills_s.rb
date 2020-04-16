require_relative 'skill.rb'

class SkillShadow < Command

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
            actor.remove_affect("follow")
        elsif ( target = actor.target({ list: actor.room.occupants, not: actor, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            if actor.stat(:dex) >= target.stat(:int)
                actor.apply_affect( AffectFollow.new( target, actor, 1 ), true )
                actor.output "You begin to secretly follow %n.", [target]
            else
                actor.output "Your attempt is painfully obvious."
                actor.apply_affect( AffectFollow.new( target, actor, 1 ) )
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
        actor.apply_affect(AffectSneak.new( actor, actor, actor.level ))
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
        if ( mobile_target = actor.target({ list: actor.room.occupants, not: actor, visible_to: actor }.merge( args[1].to_s.to_query )).first )
            if ( item_target = actor.target({ list: mobile_target.inventory.items, visible_to: actor }.merge( args[0].to_s.to_query )).first )
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
