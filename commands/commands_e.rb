require_relative 'command.rb'

class CommandEquipment < Command

    def initialize(game)
        super(
            game: game,
            name: "equipment",
            keywords: ["equipment"],
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        actor.output %Q(
You are using:
#{ actor.show_equipment }
        )
    end
end
