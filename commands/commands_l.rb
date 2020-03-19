require_relative 'command.rb'

class CommandLearn < Command
    def initialize
        super(
            name: "learn",
            keywords: ["learn"],
            position: Constants::Position::SLEEP
        )
    end

    def attempt( actor, cmd, args, input )
        actor.output "You attempt to learn."
        actor.learn( args.join(" ") )
    end
end

class CommandLeave < Command
    def initialize
        super(
            name: "leave",
            keywords: ["leave"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if actor.group.any?
            actor.output "You can't leave the group, you're the leader!"
            return false
        elsif actor.in_group.nil?
            actor.output "You're not in a group."
            return false
        else
            actor.remove_from_group
            return true
        end
    end
end

class CommandList < Command

    def initialize
        super(
            name: "list",
            keywords: ["list"],
            lag: 0,
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        ( shopkeepers = actor.target( visible_to: actor, list: actor.room.occupants, affect: "shopkeeper", not: actor ) ).each do |shopkeeper|

            actor.output "#{shopkeeper}:"

            ids_shown = []
            lines = []
            targets = Game.instance.target({ list: shopkeeper.inventory.items, visible_to: actor, quantity: 'all' })
            targets.each do |item|
                if ids_shown.include?(item.id)
                    next
                end
                quantity = targets.select{ |t| t.id == item.id }.length
                lines << "#{item.to_store_listing( quantity )}"
                ids_shown << item.id
            end
            actor.output lines.join("\n\r")

        end
        if shopkeepers.length <= 0
            actor.output "You can't do that here."
            return false
        end
        return true
    end

end

class CommandLoadItem < Command
    def initialize
        super(
            name: "loaditem",
            keywords: ["loaditem"],
            priority: 1,
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if args.length <= 0
            actor.output "Syntax: loaditem <id>"
            return false
        else
            item = Game.instance.load_item( args.first.to_i, actor.inventory )
            if !item
                actor.output "No such item."
                return false
            end
            actor.room.occupants.each_output "0<N> 0<have,has> loaded item: 1<n>.", [actor]
            return true
        end
    end
end

class CommandLock < Command

    def initialize
        super(
            name: "lock",
            keywords: ["lock"],
            lag: 0.25,
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = Game.instance.target( { list: actor.room.exits.values }.merge( args.first.to_s.to_query ) ).first )
            return target.lock( actor )
        else
            actor.output "There is no exit in that direction."
            return false
        end
    end
end

class CommandLook < Command

    def initialize
        super(
            name: "look",
            keywords: ["look"],
            priority: 200,
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if args.length <= 0
            actor.output actor.room.show( actor )
            return true
        elsif args.first == "in"
            if !args[1]
                actor.output "Look in what?"
                return false
            end
            target = actor.target({ list: actor.items + actor.room.items, visible_to: actor }.merge( args[1].to_s.to_query )).first
            if !target
                actor.output "You don't see anything like that."
                return false
            elsif !(Container === target)
                actor.output "That's not a container."
                return false
            else
                actor.output "0<N> holds:", [target]
                item_count = actor.target({list: target.inventory.items, visible_to: actor}).length
                actor.output(item_count > 0 ? target.inventory.show(observer: actor) : "Nothing.")
                return true
            end
        elsif ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            actor.output %Q(#{target.long_description}
#{target.condition}

#{target} is using:)
            target.show_equipment(actor)
            return true
        else
            actor.output "You don't see anyone like that here."
            return false
        end
    end
end

class CommandLore < Command

    def initialize
        super(
            name: "lore",
            keywords: ["lore"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if args.length <= 0
            actor.output "What did you want to lore?"
            return false
        end
        if (target = actor.target({ list: actor.items, visible_to: actor }.merge( args.first.to_s.to_query(1)) ).to_a.first)
            actor.output(target.lore)
            return true
        else
            actor.output("You can't find it.")
            return false
        end
    end
end
