require_relative 'command.rb'

class CommandInspect < Command

    def initialize
        super({
            keywords: ["inspect"],
            position: Position::REST
        })
    end

    def attempt( actor, cmd, args )
        if ( target = actor.target({ room: actor.room, keyword: args.first.to_s, type: ["Mobile"], visible_to: actor }).first )
            actor.output target.score
        end
    end
end

class CommandInventory < Command

    def initialize
        super({
            keywords: ["inventory"],
        })
    end

    def attempt( actor, cmd, args )
        actor.output %Q(
Inventory:
#{ actor.inventory.map{ |i| "#{ actor.can_see?(i) ? i.to_s : i.to_someone }" }.join("\n") }
        )
    end
end
