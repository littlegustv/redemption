require_relative 'spell.rb'

class SpellIceBolt < Spell

    def initialize(game)
        super(
            game: game,
            name: "ice bolt",
            keywords: ["ice bolt"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
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
            target = actor.target({ list: actor.room.occupants }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.deal_damage(target: target, damage: 100, noun:"ice blast", element: Constants::Element::COLD, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellIgnoreWounds < Spell
    def initialize(game)
        super(
            game: game,
            name: "ignore wounds",
            keywords: ["ignore wounds"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectIgnoreWounds.new( source: nil, target: actor, level: level, game: @game ) )
    end
end

class SpellInvisibility < Spell
    def initialize(game)
        super(
            game: game,
            name: "invisibility",
            keywords: ["invisibility"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if args.first.nil?
            target = actor
        elsif !(target = @game.target({ list: actor.room.occupants + actor.items, visible_to: actor }.merge( args.first.to_s.to_query() )).first)
            actor.output "You don't see anything like that here."
            return false
        end
        target.apply_affect( AffectInvisibility.new( source: actor, target: target, level: level, game: @game ) )
        return true
    end
end
