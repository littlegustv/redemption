require_relative 'command.rb'

class CommandInspect < Command

    def initialize(game)
        super(
            game: game,
            name: "inspect",
            keywords: ["inspect"],
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        if ( target = actor.target({ room: actor.room, type: ["Mobile", "Player"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
            actor.output target.score
            return true
        else
            actor.output "You don't see anyone like that here."
            return false
        end
    end
end

class CommandInventory < Command

    def initialize(game)
        super(
            game: game,
            name: "inventory",
            keywords: ["inventory"]
        )
    end

    def categorize( type )
        ["weapon", "armor"].include?(type) ? type : "other"
    end

    def attempt( actor, cmd, args )
        actor.output "You are carrying:"
        item_count = actor.target({list: actor.inventory.items, visible_to: actor}).length
        actor.output item_count > 0 ? "#{actor.inventory.show(observer: actor)}" : "Nothing."
#{ actor.inventory.count <= 0 ? "     Nothing." : actor.inventory.group_by { |item| categorize( item.type ) }.map{ |type, list| "\n\r{c#{type}:{x\n\r#{list.map{ |i| "#{ actor.can_see?(i) ? i.to_s : i.to_someone }" }.join("\n\r")}" }.join("\n\r") })
        return true
    end
end
