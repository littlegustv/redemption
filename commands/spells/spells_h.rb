require_relative 'spell.rb'

class SpellHarm < Spell

    def initialize(game)
        super(
            game: game,
            name: "harm",
            keywords: ["harm"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 50
        )
    end

    def cast( actor, cmd, args, input )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
        else
            super
        end
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if args.first.nil? && actor.attacking
            target = actor.attacking
        elsif !args.first.nil?
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.deal_damage(target: target, damage: 100, noun:"harm", element: Constants::Element::HOLY, type: Constants::Damage::MAGICAL)
        return true
    end
end

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
