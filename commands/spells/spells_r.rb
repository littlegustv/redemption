require_relative 'spell.rb'

class SpellRayOfTruth < Spell

    def initialize
        super(
            name: "ray of truth",
            keywords: ["ray of truth"],
            lag: 0.25,
            mana_cost: 5
        )
    end

    def cast( actor, cmd, args, input )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
            return
        else
            super
        end
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if actor.alignment <= 100
            actor.output "The energy explodes inside you!"
            target = actor
        elsif args.first.nil? && actor.attacking
            target = actor.attacking
        elsif !args.first.nil?
            target = actor.target( argument: args[0], list: actor.room.occupants ).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end

        actor.alignment = [ actor.alignment + 50, 1000 ].min
        target.receive_damage(actor, 50, :ray_of_truth)
        return true
    end
end

class SpellRefresh < Spell

    def initialize
        super(
            name: "refresh",
            keywords: ["refresh"],
            lag: 0.25,
            mana_cost: 10,
            priority: 10
        )
    end

    def cast( actor, cmd, args, input )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
        else
            super
        end
    end

    def attempt( actor, cmd, args, input, level )
        quantity = 50
        if ( target = actor.target( argument: args[0], list: actor.room.occupants ).first )
            target.output "You feel less tired."
            target.regen( 0, 0, quantity )
        elsif args.first.nil?
            actor.output "You feel less tired."
            actor.regen( 0, 0, quantity )
        else
            actor.output "They aren't here."
        end
    end
end

class SpellRemoveCurse < Spell

    def initialize
        super(
            name: "remove curse",
            keywords: ["remove curse"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target( argument: args[0], list: actor.room.occupants + actor.items + actor.room.items ).first )
            if target.affected? "curse"
                target.remove_affects_with_keywords( "curse" )
                return true
            else
                actor.output "There doesn't seem to be a curse on 0<n>.", [target]
            end
        else
            actor.output "There is no one here with that name."
            return false
        end
    end

end

class SpellRukusMagna < Spell

    def initialize
        super(
            name: "rukus magna",
            keywords: ["rukus magna"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args, input )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
            return
        else
            super
        end
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if args.first.nil? && actor.attacking
            target = actor.attacking
        elsif !args.first.nil?
            target = actor.target( argument: args[0], list: actor.room.occupants ).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        target.receive_damage(actor, 100, :rukus_magna)
        return true
    end
end
