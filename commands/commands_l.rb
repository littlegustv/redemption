require_relative 'command.rb'

class CommandLeave < Command
    def initialize(game)
        super(
            game: game,
            name: "leave",
            keywords: ["leave"],
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
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

    def initialize(game)
        super(
            game: game,
            name: "list",
            keywords: ["list"],
            lag: 0,
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        ( shopkeepers = actor.target( list: actor.room.occupants, affect: "shopkeeper" ) ).each do |shopkeeper|
            actor.output %Q(#{shopkeeper}:
#{'-'*shopkeeper.to_s.length}
[Lv Price Qty] Item
#{ shopkeeper.inventory.items.map(&:to_store_listing).join("\n\r") }
)
        end
        if shopkeepers.length <= 0
            actor.output "You can't do that here."
            return false
        end
        return true
    end

end

class CommandLoadItem < Command
    def initialize(game)
        super(
            game: game,
            name: "loaditem",
            keywords: ["loaditem"],
            priority: 1,
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        if args.length <= 0
            actor.output "Syntax: loaditem <id>"
            return false
        else
            item = actor.game.load_item( args.first.to_i, actor.inventory.items )
            if !item
                actor.output "No such item."
                return false
            end
            actor.broadcast "Loaded item: #{item}", actor.target({ room: actor.room })
            return true
        end
    end
end

class CommandLook < Command

    def initialize(game)
        super(
            game: game,
            name: "look",
            keywords: ["look"],
            priority: 200,
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        if args.length <= 0
            actor.output actor.room.show( actor )
            return true
        elsif ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            actor.output %Q(#{target.full}
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

    def initialize(game)
        super(
            game: game,
            name: "lore",
            keywords: ["lore"],
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        if args.length <= 0
            actor.output "What did you want to lore?"
            return false
        end
        if (target = actor.target({ list: actor.inventory.items + actor.equipment, visible_to: actor }.merge( args.first.to_s.to_query ).merge({ quantity: 1 })).to_a.first)
            actor.output target.lore
            return true
        else
            actor.output "You can't find it."
            return false
        end
    end
end
