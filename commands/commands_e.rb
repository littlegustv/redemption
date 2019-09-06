require_relative 'command.rb'

class CommandEquipment < Command

    def initialize
        super()
        @name = "equipment"
        @keywords = ["equipment"]
    end

    def attempt( actor, cmd, args )
        actor.output %Q(
You are using:
#{ actor.show_equipment }
        )
    end
end
