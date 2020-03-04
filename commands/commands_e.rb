require_relative 'command.rb'

class CommandEnter < Command

    def initialize
        super(
            name: "enter",
            keywords: ["enter"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = Game.instance.target({ list: actor.room.items }.merge( args.first.to_s.to_query )).first )
            data = { mobile: actor, success: false, failure_message: "You can't enter that." }
            Game.instance.fire_event( target, :event_try_enter, data)
            if !data[:success]
                actor.output data[:failure_message]
            end
        elsif args.first.nil?
            actor.output "Enter what?"
        else
            actor.output "You don't see that here."
        end
    end
end

class CommandEquipment < Command

    def initialize
        super(
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
