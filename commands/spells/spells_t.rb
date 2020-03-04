require_relative 'spell.rb'

class SpellTeleport < Spell

    def initialize
        super(
            name: "teleport",
            keywords: ["teleport"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = args.first.nil? ? actor : actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        if target
	        newroom = Game.instance.rooms.values.sample
	        target.output "You have been teleported!" if target != actor
	        Game.instance.broadcast "%s vanishes!", Game.instance.target({ list: target.room.occupants, not: target }), [target]
	        target.move_to_room newroom
	        Game.instance.broadcast "%s slowly fades into existence.", Game.instance.target({ list: newroom.occupants, not: target }), [target]
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
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = args.first.nil? ? actor : actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        if target
            target.apply_affect( AffectTaunt.new( actor, target, actor.level ) )
            target.start_combat( actor ) if target != actor
            return true
        else
            actor.output "There is no one here with that name."
            return false
        end
    end

end
