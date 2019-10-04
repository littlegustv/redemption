require_relative 'command.rb'

class CommandAffects < Command

    def initialize(game)
        super(
            game: game,
            name: "affects",
            keywords: ["affects"]
        )
    end

    def attempt( actor, cmd, args )
        actor.output actor.show_affects(observer: actor)
        return true
    end
end
