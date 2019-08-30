require_relative 'command.rb'

class CommandGet < Command

    def initialize
        super({
            keywords: ["get", "take"],
            position: Position::REST
        })
    end

    def attempt( actor, cmd, args )
        if ( target = actor.target({ room: actor.room, keyword: args.first.to_s, type: ["Item", "Weapon"], visible_to: actor }).first )
            target.room = nil
            actor.inventory.push target
            actor.output "You get #{ target }."
            actor.broadcast "%s gets %s.", actor.target({ not: actor, room: actor.room, type: "Player" }), [actor, target]
        else
            actor.output "You don't see that here."
        end
    end
end

class CommandGoTo < Command

    def initialize( game )
        @game = game
        super({
            keywords: ["goto"],
        })
    end

    def attempt( actor, cmd, args )
        area_target = actor.target({keyword: args.first.to_s, type: ["Area"]}).first
        puts "#{area_target}"
        room_target = area_target.rooms.first if area_target
        puts "#{room_target}"
        # area = @game.area_with_name( args.join(" ") )
        # room = @game.first_room_in_area( area ) if area
        if !area_target || !room_target
            actor.output "Nothing by that name."
            return
        end
        actor.move_to_room( room_target )
    end
end
