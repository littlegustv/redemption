require_relative 'spell.rb'

class SpellIceBolt < Spell

    def initialize(game)
        super(
            game: game,
            name: "ice bolt",
            keywords: ["ice bolt"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on who, now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args, level )
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
            position: Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, level )
        actor.apply_affect( AffectIgnoreWounds.new( source: actor, target: actor, level: level, game: @game ) )
    end
end

class SpellInvisibility < Spell
    def initialize(game)
        super(
            game: game,
            name: "invisibility",
            keywords: ["invisibility"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, level )
        if args.first.nil?
            actor.apply_affect( AffectInvisibility.new( source: actor, target: actor, level: level, game: @game ) )
        elsif ( target = @game.target({ list: actor.room.occupants + actor.items, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            target.apply_affect( AffectInvisibility.new( source: actor, target: target, level: level, game: @game ) )
        end
    end
end
