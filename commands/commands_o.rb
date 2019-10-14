require_relative 'command.rb'

class CommandOrder < Command

    def initialize(game)
        super(
            game: game,
            name: "order",
            keywords: ["order"],
            lag: 0.25,
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args, input )
    	if ( target = actor.target({ list: actor.room.occupants, not: actor, visible_to: actor }.merge( args.shift.to_s.to_query ) ).first )
	        @game.fire_event(  actor, :event_order, { command: args.join(" ") } )
	    else
	    	actor.output "Order whom to do what?"
        end
    end
end
