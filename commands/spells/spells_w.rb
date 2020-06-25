require_relative 'spell.rb'

class SpellWeaken < Spell

    def initialize
        super(
            name: "weaken",
            keywords: ["weaken"],
            lag: 0.25,
            mana_cost: 10
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
        AffectWeaken.new( target, actor, actor.level ).apply
        target.start_combat( actor )
        return true
    end

end

class SpellWordOfRecall < Spell

    def initialize
        super(
            name: "word of recall",
            keywords: ["word of recall"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target( argument: args[0], list: actor.room.occupants - [actor] ).first )
            target.do_command "recall"
        else
            actor.output "There is no-one here with that name."
        end
    end
end
