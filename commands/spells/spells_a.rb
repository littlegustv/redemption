require_relative 'spell.rb'

class SpellAcidBlast < Spell

    def initialize(game)
        super(
            game: game,
            name: "acid blast",
            keywords: ["acid", "blast", "acid blast"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on who, now?"
            return
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args, level )
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
        actor.deal_damage(target: target, damage: 100, noun:"acid blast", element: Constants::Element::ACID, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellAlarmRune < Spell

    def initialize(game)
        super(
            game: game,
            name: "alarm rune",
            keywords: ["alarm rune"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, level )
        if actor.affected? "alarm rune"
            actor.output "You already sense others."
            return false
        elsif actor.room.affected? "alarm rune"
            actor.output "This room is already being sensed."
            return false
        else
            actor.output "You place an alarm rune on the ground, increasing your senses."
            actor.broadcast "%s places a strange rune on the ground.", actor.target({ list: actor.room.occupants, not: actor }), [actor]
            actor.room.apply_affect( AffectAlarmRune.new( source: actor, target: actor.room, level: actor.level, game: @game ) )
            actor.apply_affect( Affect.new( name: "alarm rune", keywords: [], source: actor, target: actor, level: actor.level, duration: 10, modifiers: { none: 0 }, game: @game ) )
            return true
        end
    end
end

class SpellArmor < Spell


    def initialize(game)
        super(
            game: game,
            name: "armor",
            keywords: ["armor"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, level )
        actor.apply_affect( AffectArmor.new( source: nil, target: actor, level: actor.level, game: @game ) )
    end

end