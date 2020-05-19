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

class CommandOutfit < Command

   def initialize
        super(
            name: "outfit",
            keywords: ["outfit"],
            lag: 0.25,
            position: :standing
        )
        @@weapons = {
            mace: 2755,
            dagger: 2756,
            sword: 2757,
            spear: 2773,
            axe: 2774,
            flail: 2775,
            whip: 2776,
            polearm: 2777,
            exotic: 2783,
            katana: 2784,
        }
    end

    def attempt( actor, cmd, args, input )
        if actor.level > 5
            actor.output "Find it yourself!"
        else
            actor.wear( Game.instance.load_item( 789, actor.inventory ) ) if actor.free?( :light ) # war banner
            actor.wear( Game.instance.load_item( 2758, actor.inventory ) ) if actor.free?( :body )  # sub issue vest
            actor.wear( Game.instance.load_item( @@weapons[ actor.proficiencies.sample.name.to_sym ], actor.inventory ) ) if actor.free?( :weapon )     # weapon
            actor.output "You have been outfitted by Gabriel."
        end
    end 

end