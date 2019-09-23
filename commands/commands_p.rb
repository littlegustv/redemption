require_relative 'command.rb'

class CommandPeek < Command

    def initialize(game)
        super(
            game: game,
            name: "peek",
            keywords: ["peek"],
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        if ( target = actor.target({ room: actor.room, type: ["Mobile"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
            if target.inventory.count > 0
                actor.output "#{target} is carrying:\n#{target.inventory.map(&:to_s).join("\n")}"
                return true
            else
                actor.output "#{target} is carrying:\nNothing."
                return true
            end
        else
            actor.output "You cannot seem to catch a glimpse."
            return false
        end
    end

end

class CommandPoison < Command

    def initialize(game)
        super(
            game: game,
            name: "poison",
            keywords: ["poison"],
            position: Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        if not actor.affected? "poison"
            actor.apply_affect(AffectPoison.new(source: actor, target: actor, level: actor.level, game: @game))
            return true
        else
            actor.output "You are already poisoned."
            return false
        end
    end

end
