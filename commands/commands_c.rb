require_relative 'command.rb'

class CommandCast < Command

    def initialize
        super(
            name: "cast",
            keywords: ["cast"],
            position: :standing,
            priority: 9999
        )
        @spells = Game.instance.spells
    end

    def attempt( actor, cmd, args, input )
        spell_name = args.shift
        if spell_name.nil?
            actor.output "What spell are you trying to cast?"
            return false
        end
        matches = @spells.select{ |spell|
            spell.keywords.fuzzy_match( spell_name ) && actor.knows( spell )
        }.sort_by(&:priority)

        if matches.any?
            return matches.last.cast( actor, cmd, args, input )
        else
            actor.output "You don't have any spells of that name."
            return false
        end
    end

end

class CommandClose < Command

    def initialize
        super(
            name: "close",
            keywords: ["close"],
            lag: 0.25,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = actor.target( list: actor.room.exits, argument: args.first ).first )
            return target.close( actor )
        else
            actor.output "There is no exit in that direction."
            return false
        end
    end
end

class CommandConsider < Command

    def initialize
        super(
            name: "consider",
            keywords: ["consider"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        if args.first.nil?
            actor.output "Who did you want to consider?"
            return false
        end
        if ( target = actor.target( list: actor.room.occupants, argument: args.first ).first )
            case  target.level - actor.level
            when -51..-10
                actor.output "You can kill 0<n> naked and weaponless.", [target]
            when -9..-5
                actor.output "0<N> is no match for you.", [target]
            when -6..-2
                actor.output "0<N> looks like an easy kill.", [target]
            when -1..1
                actor.output "The perfect match!", [target]
            when 2..4
                actor.output "0<N> says 'Do you feel lucky, punk?'.", [target]
            when 5..9
                actor.output "0<N> laughs at you mercilessly.", [target]
            else
                actor.output "Death will thank you for your gift.", [target]
            end
            return true
        else
            actor.output "You don't see anyone like that here."
            return true
        end
    end

end
