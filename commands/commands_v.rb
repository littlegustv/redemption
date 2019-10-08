require_relative 'command.rb'

class CommandVisible < Command

    def initialize(game)
        super(
            game: game,
            name: "visible",
            keywords: ["visible"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args )
        actor.do_visible
        return true
    end

end
