require_relative 'command.rb'

class CommandEnter < Command

    def initialize(game)
        super(
            game: game,
            name: "enter",
            keywords: ["enter"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = @game.target({ list: actor.room.items }.merge( args.first.to_s.to_query )).first )
            if target.affected? "portal"
                @game.fire_event( target, :event_try_enter, { mobile: actor } )
            else
                actor.output "You can't enter that."
            end
        elsif args.first.nil?
            actor.output "Enter what?"
        else
            actor.output "You don't see that here."
        end
    end
end

class CommandEquipment < Command

    def initialize(game)
        super(
            game: game,
            name: "equipment",
            keywords: ["equipment"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        actor.output "You are using:"
        actor.show_equipment(actor)
        return true
    end
end
