require_relative 'command.rb'

class CommandQui < Command

    def initialize
        @keywords = ["qui"]
        @priority = 200
        @lag = 0
        @position = Position::SLEEP
    end

    def attempt( actor, cmd, args )
        actor.output "If you want to QUIT, you'll have to spell it out."
    end

end

class CommandQuicken < Command

    def initialize
        @keywords = ["quicken"]
        @priority = 100
        @lag = 0.5
        @position = Position::SLEEP
    end

    def attempt( actor, cmd, args )
        if not actor.affected? "haste"
            actor.affects.push AffectHaste.new( actor, ["quicken", "haste"], 120, { dex: 5, attack_speed: 1 } )
        else
            actor.output "You are already moving as fast as you can!"
        end
    end

end

class CommandQuit < Command

    def initialize
        @keywords = ["quit"]
        @priority = 100
        @lag = 0
        @position = Position::SLEEP
    end

    def attempt( actor, cmd, args )
        actor.quit
    end

end
