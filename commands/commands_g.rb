require_relative 'command.rb'

class CommandGroup < Command
    def initialize
        super()

        @keywords = ["group"]
        @position = Position::REST
    end

    def attempt( actor, cmd, args )
        # Display group status

        if args.empty?
            actor.output actor.group_info
            return
        end

        # Check if already in a group

        unless actor.in_group.nil?
            actor.output "You're already in a group."
            return
        end

        # Look for a target

        if ( target = actor.target({
            type: ["Player"],
            visible_to: actor,
            keyword: args.first.to_s,
            not: actor
        }).first )

        if actor.group.include? target
            target.remove_from_group
        elsif target.in_group.nil? and target.group.empty?
            target.add_to_group(actor)
        else
            actor.output "They're already in a group."
        end

        else
            actor.output "You can't find them."
        end
    end
end

class CommandGet < Command

    def initialize
        super()

        @keywords = ["get", "take"]
        @position = Position::REST
    end

    def attempt( actor, cmd, args )
        if ( targets = actor.target({ room: actor.room, type: ["Item", "Weapon"], visible_to: actor }.merge( args.first.to_s.to_query ) ) )
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
        super()

        @keywords = ["goto"]
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
