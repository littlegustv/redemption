require_relative 'command.rb'

class CommandEquipment < Command

    def initialize
        @keywords = ["equipment"]
        @priority = 100
        @lag = 0
        @position = Position::SLEEP
    end

    def attempt( actor, cmd, args )
        actor.output %Q(
You are using:
#{ actor.show_equipment }
        )
    end
end
