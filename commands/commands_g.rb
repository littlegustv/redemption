require_relative 'command.rb'

class CommandGet < Command

    def initialize(game)
        super(
            game: game,
            name: "get",
            keywords: ["get", "take"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if ( targets = actor.target({ list: actor.room.items, visible_to: actor }.merge( args.first.to_s.to_query(1) ) ) )
            targets.each do | target |
                actor.get_item(target)
            end
        else
            actor.output "You don't see that here."
        end
    end
end


class CommandGive < Command

    def initialize(game)
        super(
            game: game,
            name: "give",
            keywords: ["give"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        case args.length
        when 0
            actor.output "Give what to whom?"
            return false
        when 1
            actor.output "Give it to whom?"
            return false
        end
        items = actor.target({ list: actor.inventory.items, visible_to: actor }.merge( args[0].to_s.to_query(1) ) )
        person = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args[1].to_s.to_query(1) ) ).first
        if !items
            actor.output "You don't see that here."
            return false
        end
        if !person
            actor.output "They aren't here."
            return false
        end
        items.each do | item |
            if person.can_see?(item)
                actor.give_item(item, person)
            else
                actor.output "They can't see %s.", item
            end
        end
        return true
    end
end

class CommandGoTo < Command

    def initialize(game)
        super(
            game: game,
            name: "goto",
            keywords: ["goto"]
        )
    end

    def attempt( actor, cmd, args, input )
        area_target = actor.target({type: ["Area"]}.merge( args.first.to_s.to_query() )).first
        room_target = area_target.rooms.first if area_target
        if !area_target || !room_target
            actor.output "Nothing by that name."
            return
        end
        actor.move_to_room( room_target )
    end
end

class CommandGroup < Command
    def initialize(game)
        super(
            game: game,
            name: "group",
            keywords: ["group"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
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
            return true
        elsif target.in_group.nil? and target.group.empty?
            target.add_to_group(actor)
            return true
        else
            actor.output "They're already in a group."
            return false
        end

        else
            actor.output "You can't find them."
            return false
        end
    end
end
