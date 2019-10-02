require_relative 'command.rb'

class CommandOrder < Command

    def initialize(game)
        super(
            game: game,
            name: "order",
            keywords: ["order"],
            lag: 0.25,
            position: Position::STAND
        )
    end

    def attempt( actor, cmd, args )
    	if ( target = actor.target({ list: actor.room.occupants, not: actor }.merge( args.shift.to_s.to_query ) ).first )
	        @game.fire_event( :event_order, { master: actor, command: args.join(" ") }, target )
	    else
	    	actor.output "Order whom to do what?"
	    end
    end
end