require_relative 'command.rb'

class CommandVisible < Command

    def initialize
        super(
            name: "visible",
            keywords: ["visible"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        actor.do_visible
        return true
    end

end
