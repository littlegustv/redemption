require_relative 'command.rb'

class CommandMove < Command

    def initialize(game)
        super(
            game: game,
            name: "move",
            keywords: ["north", "east", "south", "west", "up", "down"],
            priority: 1000,
            lag: 0.25,
            usable_in_combat: false,
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        direction = @keywords.select{ |keyword| keyword.fuzzy_match( cmd ) }.first
        return actor.move direction
    end
end
