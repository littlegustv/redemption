require_relative 'command.rb'

class CommandAffects < Command

    def initialize
        @keywords = ["affects"]
        @priority = 100
        @lag = 0
        @position = Position::SLEEP
    end

    def attempt( actor, cmd, args )
        actor.output %Q(
You are affected by the following spells:
#{ actor.affects.map(&:summary).join("\n") }
        )
    end
end
