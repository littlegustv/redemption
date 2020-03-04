require_relative 'command.rb'

class CommandInspect < Command

    def initialize
        super(
            name: "inspect",
            keywords: ["inspect"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            actor.output target.score
            return true
        else
            actor.output "You don't see anyone like that here."
            return false
        end
    end
end

class CommandInventory < Command

    def initialize
        super(
            name: "inventory",
            keywords: ["inventory"]
        )
    end

    def categorize( type )
        ["weapon", "armor"].include?(type) ? type : "other"
    end

    def attempt( actor, cmd, args, input )
        actor.output "You are carrying:"
        item_count = actor.target({list: actor.inventory.items, visible_to: actor}).length
        actor.output item_count > 0 ? "#{actor.inventory.show(observer: actor)}" : "Nothing."
        return true
    end
end
