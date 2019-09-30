require_relative 'command.rb'

class CommandQuicken < Command

    def initialize(game)
        super(
            game: game,
            name: "quicken",
            keywords: ["quicken"],
            lag: 0.5,
            position: Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        if not actor.affected? "haste"
            actor.apply_affect(AffectHaste.new(source: actor, target: actor, level: actor.level, game: @game))
            return true
        else
            actor.output "You are already moving as fast as you can!"
            return false
        end
    end

end

class CommandQuit < Command

    def initialize(game)
        super(
            game: game,
            name: "quit",
            keywords: ["quit"],
            priority: 0,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args )
        if cmd.downcase != "quit"
            actor.output "If you want to QUIT, you'll have to spell it out."
            return
        end
        if actor.respond_to?(:quit)
            return actor.quit
        else
            actor.output "Only players can quit!"
            return false
        end
    end

end
