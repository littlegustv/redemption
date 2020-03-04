require_relative 'spell.rb'

class SpellWeaken < Spell

    def initialize
        super(
            name: "weaken",
            keywords: ["weaken"],
            lag: 0.25,
            position: Constants::Position::STAND,
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        target.apply_affect( AffectWeaken.new( actor, target, actor.level ) )
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
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target({ list: actor.room.occupants, not: actor, visible_to: actor }.merge( args.shift.to_s.to_query ) ).first )
            target.do_command "recall"
        else
            actor.output "There is no-one here with that name."
        end
    end
end
