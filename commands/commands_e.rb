require_relative 'command.rb'

class CommandEat < Command

    def initialize
        super(
            name: "eat",
            keywords: ["eat"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = actor.target({ list: actor.items, item_type: "pill", visible_to: actor }.merge( args.first.to_s.to_query )).first )
            actor.room.occupants.each_output "0<N> 0<eat,eats> 1<n>", [actor, target]
            target.consume( actor )
        else
            actor.output("You don't see that here.")
        end
    end

end

class CommandEmote < Command

    def initialize
        super(
            name: "emote",
            keywords: ["emote"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if args.length <= 0
            actor.output 'Emote what?'
            return false
        else
            message = input[/#{cmd} (.*)/, 1]
            actor.room.occupants.each_output "0<N> #{message}", [actor]
            return true
        end
    end

end

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
