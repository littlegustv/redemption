require_relative 'command.rb'

class CommandKill < Command

    def initialize(game)
        super(
            game: game,
            name: "kill",
            keywords: ["kill", "hit"],
            lag: 0.5,
            position: Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        keyword = @keywords.select{ |keyword| keyword.fuzzy_match( cmd ) }.first
        if args.length <= 0
            actor.output "Who did you want to #{keyword}?"
            return false
        end
        if actor.position < Position::STAND
            actor.output "You have to stand up first."
            return false
        elsif actor.attacking
            actor.output "You are already fighting!"
            return false
        elsif ( kill_target = actor.target({ list: actor.room.occupants, not: actor, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            actor.do_round_of_attacks(target: kill_target)
            return true
        else
            actor.output "I can't find anyone with that name."
            return false
        end
    end
end
