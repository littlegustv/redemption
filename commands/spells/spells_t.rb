require_relative 'spell.rb'

class SpellTeleport < Spell

    def initialize
        super(
            name: "teleport",
            keywords: ["teleport"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = args.first.nil? ? actor : actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        if target
	        newroom = Game.instance.rooms.values.sample
	        target.output "You have been teleported!" if target != actor
	        (target.room.occupants - [target]).each_output "0<N> vanishes!", [target]
	        target.move_to_room newroom
	        (target.room.occupants - [target]).each_output "0<N> materializes suddenly.", [target]
	    else
	    	actor.output "Teleport who?"
        end
    end

end

class SpellTaunt < Spell

    def initialize
        super(
            name: "taunt",
            keywords: ["taunt"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = args.first.nil? ? actor : actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        if target
             AffectTaunt.new( target, actor, actor.level ).apply
            target.start_combat( actor ) if target != actor
            return true
        else
            actor.output "There is no one here with that name."
            return false
        end
    end

end
