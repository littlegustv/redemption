require_relative 'spell.rb'

class SpellHurricane < Spell

    def initialize(game)
        super(
            game: game,
            name: "hurricane",
            keywords: ["hurricane"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, level )
        actor.broadcast "%s summons a hurricane!", actor.target({ not: actor, list: actor.room.occupants, type: ["Mobile", "Player"] }), [actor]
        actor.output "You summon a hurricane!"
    	( targets = actor.target({ not: actor, quantity: "all", room: actor.room, type: ["Mobile", "Player"] })).each do |target|
    		actor.magic_hit( target, 100, "hurricane", "flooding" )
            return true
    	end
    end
end
