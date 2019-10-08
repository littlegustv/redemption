require_relative 'spell.rb'

class SpellHurricane < Spell

    def initialize(game)
        super(
            game: game,
            name: "hurricane",
            keywords: ["hurricane"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.broadcast "%s summons a hurricane!", actor.target({ not: actor, list: actor.room.occupants, type: ["Mobile", "Player"] }), [actor]
        actor.output "You summon a hurricane!"
    	( targets = actor.target({ not: actor, list: actor.room.occupants })).each do |target|
    		actor.deal_damage(target: target, damage: 100, noun:"hurricane", element: Constants::Element::DROWNING, type: Constants::Damage::MAGICAL)
    	end
        return true
    end
end
