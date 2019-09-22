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
        elsif actor.in_group.nil?
            actor.output "You're not in a group."
        else
            actor.remove_from_group
        end
    end
end

class CommandList < Command

    def initialize(game)
        super(
            name: "list",
            keywords: ["list"],
            lag: 0,
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        ( shopkeepers = actor.target( list: actor.room.mobiles, affect: "shopkeeper" ) ).each do |shopkeeper|
            actor.output %Q(#{shopkeeper}:
#{'-'*shopkeeper.to_s.length}          
[Lv Price Qty] Item
#{ shopkeeper.inventory.map(&:to_store_listing).join("\n\r") }
)
        end
        if shopkeepers.length <= 0
            actor.output "You can't do that here."
        end
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
        else
            item = actor.game.load_item( args.first.to_i, actor.room )
            actor.broadcast "Loaded item: #{item}", actor.target({ room: actor.room })
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
        elsif ( target = actor.target({ room: actor.room, type: ["Mobile"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
            actor.output %Q(#{target.full}
#{target.condition}

#{target} is using:
#{target.show_equipment})
        else
            actor.output "You don't see anyone like that here."
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
            return
        end
        if (target = actor.target({ list: actor.inventory + actor.equipment.values, visible_to: actor }.merge( args.first.to_s.to_query ).merge({ quantity: 1 })).to_a.first)
            actor.output target.lore
        else
            actor.output "You can't find it."
        end
    end
end
