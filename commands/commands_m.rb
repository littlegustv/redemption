require_relative 'command.rb'

class CommandMove < Command

    def initialize
        @keywords = ["north", "east", "south", "west", "up", "down"]
        @priority = 200
        @lag = 0.5
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
        direction = @keywords.select{ |keyword| keyword.fuzzy_match( cmd ) }.first
        actor.move direction
    end
end
