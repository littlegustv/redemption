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
        AffectLair.new( actor.room, actor, actor.level ).apply
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
        @data = {
            heal: "(3*[level])+([level]/4)d[wisdom]",
            cooldown: 600
        }
    end

    def attempt( actor, cmd, args, input )
        if actor.cooldown(:lay_hands)
            actor.output "You are too tired."
            return false
        end
        if dice(1, 100) < actor.stat(:failure)
            actor.output "You failed your attempt to lay hands!"
            return true
        end
        actor.add_cooldown(:lay_hands, @data[:cooldown], "Your healing powers are restored.")
        target = actor
        if args[1]
            if !(target = actor.target( argument: args[0], list: actor.room.occupants ).first)
                actor.output "You don't see them here."
                return false
            end
        end
        formula = Formula.new(@data[:heal])
        heal = formula.evaluate([actor])
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
