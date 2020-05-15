require_relative 'skill.rb'

class SkillLair < Skill

    def initialize
        super(
            name: "lair",
            keywords: ["lair"],
            lag: 0.25,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        AffectLair.new( actor, actor.room, actor.level ).apply
    end

end

class SkillLayHands < Skill

    def initialize
        super(
            name: "lay hands",
            keywords: ["lay hands"],
            lag: 1,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if actor.cooldown(:lay_hands)
            actor.output "You are too tired."
            return false
        end
        actor.add_cooldown(:lay_hands, 10 * 60)
        target = actor
        if args[1]
            if !(target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first)
                actor.output "You don't see them here."
                return false
            end
        end
        heal = 200
        target.receive_heal(actor, heal, :lay_hands)
    end
end


class SkillLivingStone < Skill

    def initialize
        super(
            name: "living stone",
            keywords: ["living stone", "stone", "living"],
            lag: 1,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if not actor.affected? "living stone"
            AffectLivingStone.new( actor, actor, actor.level ).apply
            return true
        else
            actor.output "You did not manage to turn to stone."
            return false
        end
    end
end
