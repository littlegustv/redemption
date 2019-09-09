require_relative 'command.rb'

class CommandAffects < Command

    def initialize
        super(
            name: "affects",
            keywords: ["affects"]
        )
    end

    def attempt( actor, cmd, args )
        actor.output "You are affected by the following spells:\n#{ actor.affects.map(&:summary).join("\n") }"
    end
end
