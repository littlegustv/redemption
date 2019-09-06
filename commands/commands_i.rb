require_relative 'command.rb'

class CommandInspect < Command

    def initialize
        super()

        @keywords = ["inspect"]
        @position = Position::REST
    end

    def attempt( actor, cmd, args )
        if ( target = actor.target({ room: actor.room, type: ["Mobile", "Player"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
            actor.output target.score
        else
            actor.output "You don't see anyone like that here."
        end
    end
end

class CommandInventory < Command

    def initialize
        super()

        @keywords = ["inventory"]
    end

    def attempt( actor, cmd, args )
        actor.output %Q(
Inventory:
#{ actor.inventory.map{ |i| "#{ actor.can_see?(i) ? i.to_s : i.to_someone }" }.join("\n") }
        )
    end
end
