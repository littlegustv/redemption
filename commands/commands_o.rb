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
        if ( target = actor.target( argument: args[0], list: actor.room.exits ).first )
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
    	if ( target = actor.target( argument: args.shift, list: actor.room.occupants - [actor] ).first )
	        Game.instance.fire_event(  actor, :order, { command: args.join(" ") } )
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
            genres = @@weapons.keys.map(&:to_genre) & actor.proficiencies
            if genres.empty?
                actor.output "Some people just can't be helped!"
                return
            elsif !actor.free?( :weapon )
                actor.output "You don't seem to need a weapon. Maybe try removing one?"
                return
            end
            item = @@weapons[genres.sample.symbol]
            actor.wear( Game.instance.load_item( item, actor.inventory ) )    # weapon
            actor.output "You have been outfitted by Gabriel."
        end
    end

end
