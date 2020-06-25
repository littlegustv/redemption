require_relative 'command.rb'

class CommandInspect < Command

    def initialize
        super(
            name: "inspect",
            keywords: ["inspect"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = actor.target( argument: args[0], list: actor.room.occupants ).first )
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
        item_count = actor.target( list: actor.inventory.items ).length
        actor.output (actor.inventory.show(actor, false, "Nothing."))
        return true
    end
end
