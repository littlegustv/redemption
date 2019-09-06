require_relative 'command.rb'

class CommandQui < Command

    def initialize
        super()
        @name = "qui"
        @keywords = ["qui"]
        @priority = 201
    end

    def attempt( actor, cmd, args )
        actor.output "If you want to QUIT, you'll have to spell it out."
    end

end

class CommandQuicken < Command

    def initialize
        super
        @name = "quicken"
        @keywords = ["quicken"]
        @lag = 0.5
        @position = Position::STAND
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
        super
        @name = "quit"
        @keywords = ["quit"]
        @priority = 200
        @usable_in_combat = false
    end

    def attempt( actor, cmd, args )
        actor.quit
    end

end
