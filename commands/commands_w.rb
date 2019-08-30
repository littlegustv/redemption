require_relative 'command.rb'

class CommandWear < Command

    def initialize
        @keywords = ["wear", "hold", "wield"]
        @priority = 100
        @lag = 0
        @position = Position::REST
    end

    def attempt( actor, cmd, args )
        actor.wear args
    end

end

class CommandWhere < Command

    def initialize
        @keywords = ["where"]
        @priority = 100
        @lag = 0
        @position = Position::REST
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

    def initialize
        @keywords = [""]
        @priority = 1000
        @lag = 0
        @position = Position::SLEEP
    end

    def attempt( actor, cmd, args )
        actor.delayed_output
    end

end

class CommandWho < Command

    def initialize
        @keywords = ["who"]
        @priority = 200
        @lag = 0
        @position = Position::SLEEP
    end

    def attempt( actor, cmd, args )
        targets = actor.target( { type: "Player", visible_to: actor } )
        actor.output %Q(
----==== Characters on Terra ====----

#{ targets.select{ |t| t.room.continent == "terra" }.map(&:who).join("\n") }

----==== Characters on Dominia ====----

#{ targets.select{ |t| t.room.continent == "dominia" }.map(&:who).join("\n") }

Players found: #{targets.count})
    end

end
