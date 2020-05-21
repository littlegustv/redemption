require_relative 'command.rb'

class CommandServerReload < Command

    def initialize
        super(
            name: "reload",
            keywords: ["reload"]
        )
    end

    def attempt( actor, cmd, args, input )
        log "Initiating server reload..."
        Game.instance.initiate_reload
    end

end


class CommandServerStop < Command

    def initialize
        super(
            name: "stop",
            keywords: ["stop", "exit", "quit"]
        )
    end

    def attempt( actor, cmd, args, input )
        log "Initiating server shutdown..."
        Game.instance.initiate_stop
    end

end

class CommandServerWhitespace < Command

    def initialize
        super(
            name: "whitespace",
            keywords: [""],
            priority: 99999
        )
    end

    def attempt( actor, cmd, args, input )
        return true
    end

end
