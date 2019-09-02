require_relative 'command.rb'

class CommandGet < Command

    def initialize
        super({
            keywords: ["get", "take"],
            position: Position::REST
        })
    end

    def attempt( actor, cmd, args )
        if ( targets = actor.target({ room: actor.room, type: ["Item", "Weapon"], visible_to: actor }.merge( parse( args.first.to_s ) ) ) )
            targets.each do | target |
                target.room = nil
                actor.inventory.push target
                actor.output "You get #{ target }."
                actor.broadcast "%s gets %s.", actor.target({ not: actor, room: actor.room, type: "Player" }), [actor, target]
            end
        else
            actor.output "You don't see that here."
        end
    end
end

class CommandGoTo < Command

    def initialize
        super({
            keywords: ["goto"],
        })
    end

    def attempt( actor, cmd, args )
        area_target = actor.target({keyword: args.first.to_s, type: ["Area"]}).first
        room_target = area_target.rooms.first if area_target
        if !area_target || !room_target
            actor.output "Nothing by that name."
            return
        end
        actor.move_to_room( room_target )
    end
end
