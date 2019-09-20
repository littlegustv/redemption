require_relative 'command.rb'

class CommandKill < Command

    def initialize(game)
        super(
            game: game,
            name: "kill",
            keywords: ["kill", "hit"],
            lag: 0.5,
            starts_combat: true,
            position: Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        keyword = @keywords.select{ |keyword| keyword.fuzzy_match( cmd ) }.first
        if args.length <= 0
            actor.output "Who did you want to #{keyword}?"
            return
        end
        if actor.position < Position::STAND
            actor.output "You have to stand up first."
        elsif actor.position >= Position::FIGHT
            actor.output "You are already fighting!"
        elsif ( kill_target = actor.target({ room: actor.room, not: actor, type: ["Mobile", "Player"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
            kill_target.start_combat actor
            actor.start_combat kill_target
        else
            actor.output "I can't find anyone with that name."
        end
    end
end
