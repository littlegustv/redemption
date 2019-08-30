require_relative 'command.rb'

class CommandMove < Command

    def initialize
        super({
            keywords: ["north", "east", "south", "west", "up", "down"],
            priority: 1000,
            lag: 0.25,
            usable_while_fighting: false,
            position: Position::STAND
        })
    end

    def attempt( actor, cmd, args )
        direction = @keywords.select{ |keyword| keyword.fuzzy_match( cmd ) }.first
        actor.move direction
    end
end
