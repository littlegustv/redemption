require_relative 'command.rb'

class CommandWear < Command

    def initialize(game)
        super(
            game: game,
            name: "wear",
            keywords: ["wear", "hold", "wield"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if args.first == "all"
            actor.wear_all
            return true
        end
        if ( targets = actor.target({ visible_to: actor, list: actor.inventory.items }.merge( args.first.to_s.to_query(1) )) )
            targets.each do |target|
                actor.wear(item: target)
            end
            return true
        else
            actor.output "You don't have that."
            return false
        end
    end

end

class CommandWhere < Command

    def initialize(game)
        super(
            game: game,
            name: "where",
            keywords: ["where"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        targets = actor.target( { type: "Player", area: actor.room.area, visible_to: actor } )
        actor.output %Q(
Current Area: #{ actor.room.area }. Level Range: ? ?
Players near you:
#{ targets.map{ |t| "#{t.to_s.lpad(28)} #{t.room}" }.join("\n") })
        return true
    end

end

class CommandWhitespace < Command

    def initialize(game)
        super(
            game: game,
            name: "whitespace",
            keywords: [""],
            priority: 99999
        )
    end

    def attempt( actor, cmd, args, input )
        actor.delayed_output
        return true
    end

end

class CommandWho < Command

    def initialize(game)
        super(
            game: game,
            name: "who",
            keywords: ["who"],
            priority: 200
        )
    end

    def attempt( actor, cmd, args, input )
        targets = actor.target( { type: "Player", visible_to: actor } )
        out = ""
        @game.continents.values.each do |continent|
            out += "----==== Characters #{continent.preposition} #{continent.name} ====----\n"
            out += "\n#{ targets.select{ |t| t.room.continent == continent }.map(&:who).join("\n")}\n\n"
        end
        out += "Players found: #{targets.count}"
        actor.output(out)
        return true
    end

end

class CommandWorth < Command

    def initialize(game)
        super(
            game: game,
            name: "worth",
            keywords: ["worth"],
            priority: 200,
            lag: 0
        )
    end

    def attempt( actor, cmd, args, input )
        actor.output "You have #{actor.to_worth}"
        return true
    end

end
