require_relative 'command.rb'

class CommandDrop < Command

    def initialize
        super(
            name: "drop",
            keywords: ["drop"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        if ( targets = actor.target( list: actor.inventory.items, argument: args.first ) )
            targets.each do |target|
                actor.drop_item(target)
            end
            return true
        else
            actor.output "You don't have that."
            return false
        end
    end
end
