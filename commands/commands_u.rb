require_relative 'command.rb'

class CommandUnlock < Command

    def initialize(game)
        super(
            game: game,
            name: "unlock",
            keywords: ["unlock"],
            lag: 0.25,
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = @game.target( { list: actor.room.exits.values }.merge( args.first.to_s.to_query ) ).first )
            return target.unlock( actor )
        else
            actor.output "There is no exit in that direction."
            return false
        end
    end
end
