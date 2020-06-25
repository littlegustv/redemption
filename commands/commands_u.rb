require_relative 'command.rb'

class CommandUnlock < Command

    def initialize
        super(
            name: "unlock",
            keywords: ["unlock"],
            lag: 0.25,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = actor.target( argument: args[0], list: actor.room.exits ).first )
            return target.unlock( actor )
        else
            actor.output "There is no exit in that direction."
            return false
        end
    end
end
