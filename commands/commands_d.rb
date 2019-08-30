require_relative 'command.rb'

class CommandDrop < Command

    def initialize
        @keywords = ["drop"]
        @priority = 100
        @lag = 0
        @position = Position::REST
    end

    def attempt( actor, cmd, args )
        if ( target = actor.inventory.select { |item| item.fuzzy_match( args.first.to_s ) && actor.can_see?(item) }.first )
            target.room = actor.room
            actor.inventory.delete target
            actor.output "You drop #{target}."
            actor.broadcast "%s drops %s.", actor.target({ not: actor, room: actor.room, type: "Player" }), [actor, target]
        else
            actor.output "You don't have that."
        end
    end
end
