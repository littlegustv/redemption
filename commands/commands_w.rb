require_relative 'command.rb'

class CommandWear < Command

    def initialize(game)
        super(
            game: game,
            name: "wear",
            keywords: ["wear", "hold", "wield"],
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        actor.wear args
    end

end

class CommandWhere < Command

    def initialize(game)
        super(
            game: game,
            name: "where",
            keywords: ["where"],
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        targets = actor.target( { type: "Player", area: actor.room.area, visible_to: actor } )
        actor.output %Q(
Current Area: #{ actor.room.area }. Level Range: ? ?
Players near you:
#{ targets.map{ |t| "#{t.to_s.ljust(28)} #{t.room}" }.join("\n") }
        )
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

    def attempt( actor, cmd, args )
        actor.delayed_output
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

    def attempt( actor, cmd, args )
        targets = actor.target( { type: "Player", visible_to: actor, quantity: "all" } )
        out = ""
        @game.continents.values.each do |continent|
            out += "----==== Characters #{continent.preposition} #{continent.name} ====----\n"
            out += "\n#{ targets.select{ |t| t.room.continent == continent }.map(&:who).join("\n")}\n\n"
        end
        out += "Players found: #{targets.count}"
        actor.output(out)
    end

end

class CommandWorth < Command

    def initialize(game)
        super(
            name: "worth",
            keywords: ["worth"],
            priority: 200,
            lag: 0
        )
    end

    def attempt( actor, cmd, args )
        actor.output "You have #{actor.to_worth}"
    end

end