require_relative 'command.rb'

class CommandDrop < Command

    def initialize(game)
        super(
            game: game,
            name: "drop",
            keywords: ["drop"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if ( targets = actor.target({ visible_to: actor, list: actor.inventory.items }.merge( args.first.to_s.to_query(1) )) )
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
