require_relative 'command.rb'

class CommandMove < Command

    def initialize
        super(
            name: "move",
            keywords: ["north", "east", "south", "west", "up", "down"],
            priority: 1000,
            lag: 0.25,
            usable_in_combat: false,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        direction = Game.instance.directions.values.find{ |d| d.name.fuzzy_match(cmd) }
        return actor.move direction
    end
end
