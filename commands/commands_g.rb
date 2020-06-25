require_relative 'command.rb'

class CommandGet < Command

    def initialize
        super(
            name: "get",
            keywords: ["get", "take"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        list = actor.room.items
        if args.dig(1) == "from"
            args[1] = args.dig(2)
        end
        if args.dig(1)
            container = actor.target( argument: args[1], list: actor.items + actor.room.items ).first
            if !container
                actor.output "You don't see that container here."
                return false
            elsif !(Container === container)
                actor.output "That's not a container."
                return false
            end
            list = container.inventory.items
        end
        if ( targets = actor.target( argument: args.first, list: list ) )
            targets.each do |t|
                actor.get_item(t)
            end
        else
            actor.output "You don't see that here."
        end
    end
end


class CommandGive < Command

    def initialize
        super(
            name: "give",
            keywords: ["give"],
            position: :resting
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
        items = actor.target( argument: args[0], list: actor.inventory.items )
        person = actor.target( argument: args[1], list: actor.room.occupants ).first
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
                actor.output "They can't see 0<n>.", [item]
            end
        end
        return true
    end
end

class CommandGoTo < Command

    def initialize
        super(
            name: "goto",
            keywords: ["goto"]
        )
    end

    def attempt( actor, cmd, args, input )
        area_target = actor.target(argument: args[0], type: Area).first
        room_target = area_target.rooms.first if area_target
        if !area_target || !room_target
            actor.output "Nothing by that name."
            return false
        end
        actor.move_to_room( room_target )
        return true
    end
end

class CommandGroup < Command
    def initialize
        super(
            name: "group",
            keywords: ["group"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        
        if args.empty?
            actor.group.output( actor )
        elsif "invite".fuzzy_match args.first.to_s
            # create/get group, find player in (room/game?) and add to invited - also notify them
            if ( target = actor.target( argument: args[1], list: Game.instance.players - [actor] ).first )
                actor.group.invited << target
                target.output "{C#{ actor }{x has invited you to join their group! Type {C'group accept #{ actor }'{x to accept the invitation."
            else
                actor.output "Invite who? There is no-one with that name."
            end
        elsif "accept".fuzzy_match args.first.to_s
            # get player from arg -> get their group -> check if self in invited list, if so, add to actual list
            if ( target = actor.target( argument: args[1], list: Game.instance.players - [actor] ).first )
                if actor.group.joined.count > 1
                    actor.output "You are already in a group! Type {C'group leave'{x to leave your current group."
                elsif target.group.invited.include? actor
                    actor.join_group( target.group )
                else
                    actor.output "You can't join their group, sorry!"
                end
            else
                actor.output "Join whose group? There is no-one with that name."
            end
        elsif "leave".fuzzy_match args.first.to_s
            # same as above, but remove from actual list
            if actor.group.joined.count <= 1
                actor.output "You aren't in a group!"
            else
                actor.leave_group
            end
        else
            actor.output "Valid group commands are {Cinvite{c, {Caccept{x, and {Cleave{x."
        end
    end
end