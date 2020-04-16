require_relative 'command.rb'

class CommandOpen < Command

    def initialize
        super(
            name: "open",
            keywords: ["open"],
            lag: 0.25,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = Game.instance.target( { list: actor.room.exits.values }.merge( args.first.to_s.to_query ) ).first )
            return target.open( actor )
        else
            actor.output "There is no exit in that direction."
            return false
        end
    end
end

class CommandOrder < Command

    def initialize
        super(
            name: "order",
            keywords: ["order"],
            lag: 0.25,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
    	if ( target = actor.target({ list: actor.room.occupants, not: actor, visible_to: actor }.merge( args.shift.to_s.to_query ) ).first )
	        Game.instance.fire_event(  actor, :event_order, { command: args.join(" ") } )
	    else
	    	actor.output "Order whom to do what?"
        end
    end
end
