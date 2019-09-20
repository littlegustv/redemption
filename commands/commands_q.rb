require_relative 'command.rb'

class CommandQui < Command

    def initialize(game)
        super(
            game: game,
            name: "qui",
            keywords: ["qui"],
            priority: 201
        )
    end

    def attempt( actor, cmd, args )
        actor.output "If you want to QUIT, you'll have to spell it out."
    end

end

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
        else
            actor.output "You are already moving as fast as you can!"
        end
    end

end

class CommandQuit < Command

    def initialize(game)
        super(
            game: game,
            name: "quit",
            keywords: ["quit"],
            priority: 200,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args )
        actor.quit
    end

end
