require_relative 'spell.rb'

class SpellFireball < Spell

    def initialize(game)
        super(
            game: game,
            name: "fireball",
            keywords: ["fireball"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.broadcast "%s summons a burning ball of fire!", actor.target({ not: actor, list: actor.room.occupants, type: ["Mobile", "Player"] }), [actor]
        actor.output "You summon a fireball!"
        ( targets = actor.target({ not: actor, list: actor.room.occupants })).each do |target|
            actor.deal_damage(target: target, damage: 100, noun:"fireball", element: Constants::Element::FIRE, type: Constants::Damage::MAGICAL)
        end
        return true
    end
end

class SpellFireRune < Spell

    def initialize(game)
        super(
            game: game,
            name: "fire rune",
            keywords: ["fire rune"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
    	if actor.room.affected? "fire rune"
    		actor.output "This room is already affected by the power of flames."
            return false
    	else
    		actor.output "You place a fiery rune on the ground to singe your foes."
    		actor.broadcast "%s places a strange rune on the ground.", actor.target({ list: actor.room.occupants, not: actor }), [actor]
    		actor.room.apply_affect( AffectFireRune.new( source: actor, target: actor.room, level: actor.level, game: @game ) )
            return true
    	end
    end
end

class SpellFlamestrike < Spell

    def initialize(game)
        super(
            game: game,
            name: "flamestrike",
            keywords: ["flamestrike"],
            lag: 0.25,
            position: Constants::Position::STAND
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
        actor.deal_damage(target: target, damage: 100, noun:"flamestrike", element: Constants::Element::FIRE, type: Constants::Damage::MAGICAL)
        return true
    end
end