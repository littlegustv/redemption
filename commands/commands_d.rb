require_relative 'command.rb'

class CommandDrop < Command

    def initialize
        super({
            keywords: ["drop"],
            lag: 0.5,
            position: Position::REST
        })
    end

    def attempt( actor, cmd, args )
        if ( targets = actor.target({ inventory: actor.inventory }.merge( parse( args.first.to_s ))) )
            targets.each do |target|
                target.room = actor.room
                actor.inventory.delete target
                actor.output "You drop #{target}."
                actor.broadcast "%s drops %s.", actor.target({ not: actor, room: actor.room, type: "Player" }), [actor, target]
            end
        else
            actor.output "You don't have that."
        end
    end
end
