require_relative 'command.rb'

class CommandPeek < Command

    def initialize
        @keywords = ["peek"]
        @priority = 100
        @lag = 0
        @position = Position::REST
    end

    def attempt( actor, cmd, args )
        if ( target = actor.target({ room: actor.room, keyword: args.first.to_s, type: ["Mobile"], visible_to: actor }).first )
            if target.inventory.count > 0
                actor.output "#{target} is carrying:\n#{target.inventory.map(&:to_s).join("\n")}"
            else
                actor.output "#{target} is carrying:\nNothing."
            end
        else
            actor.output "You cannot seem to catch a glimpse."
        end
    end

end

class CommandPoison < Command

    def initialize
        @keywords = ["poison"]
        @priority = 100
        @lag = 0
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
        if not actor.affected? "poison"
            actor.affects.push AffectPoison.new( actor, ["poison"], 180, { str: -1 }, 10 )
        else
            actor.output "You are already poisoned."
        end
    end

end
