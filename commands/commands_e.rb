require_relative 'command.rb'

class CommandEquipment < Command

    def initialize(game)
        super(
            game: game,
            name: "equipment",
            keywords: ["equipment"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args )
        actor.output "You are using:"
        actor.show_equipment(actor)
        return true
    end
end
