require_relative 'command.rb'

class CommandBlind < Command

    def initialize(game)
        super(
            game: game,
            name: "blind",
            keywords: ["blind"],
            lag: 0.4,
            position: Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        if not actor.affected? "blind"
            actor.output "You have been blinded!"
            actor.apply_affect(AffectBlind.new(source: actor, target: actor, level: actor.level, game: @game))
        else
            actor.output "You are already blind!"
        end
    end
end
