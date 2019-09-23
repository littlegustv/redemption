require_relative 'command.rb'

class CommandCast < Command

    def initialize(game)
        super(
            game: game,
            name: "cast",
            keywords: ["cast"],
            position: Position::STAND,
            priority: 9999
        )
        @spells = game.spells
    end

    def attempt( actor, cmd, args )
        spell_name = args.shift
        if spell_name.nil?
            actor.output "What spell are you trying to cast?"
            return false
        end
        matches = @spells.select{ |spell|
            spell.check( spell_name ) && actor.knows( spell.to_s )
        }.sort_by(&:priority)

        if matches.any?
            return matches.last.cast( actor, cmd, args )
        else
            actor.output "You don't have any spells of that name."
            return false
        end
    end

end

class CommandConsider < Command

    def initialize(game)
        super(
            game: game,
            name: "consider",
            keywords: ["consider"],
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        if args.first.nil?
            actor.output "Who did you want to consider?"
            return false
        end
        if ( target = actor.target({ room: actor.room, type: ["Mobile"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
            case  target.level - actor.level
            when -51..-10
                actor.output "You can kill #{target} naked and weaponless."
            when -9..-5
                actor.output "#{target} is no match for you."
            when -6..-2
                actor.output "#{target} looks like an easy kill."
            when -1..1
                actor.output "The perfect match!"
            when 2..4
                actor.output "#{target} says 'Do you feel lucky, punk?'."
            when 5..9
                actor.output "#{target} laughs at you mercilessly."
            else
                actor.output "Death will thank you for your gift.";
            end
            return true
        else
            actor.output "You don't see anyone like that here."
            return true
        end
    end

end
