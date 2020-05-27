require_relative 'command.rb'

class CommandAffects < Command

    def initialize
        super(
            name: "affects",
            keywords: "affects"
        )
    end

    def attempt( actor, cmd, args, input )
        actor.output actor.show_affects(observer: actor)
        return true
    end
end
