require_relative 'spell.rb'

class SpellEarthquake < Spell

    def initialize(game)
        super(
            game: game,
            name: "earthquake",
            keywords: ["earthquake"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, level )
        actor.broadcast "%s makes the earth tremble and shiver.", actor.target({ not: actor, list: actor.room.area.occupants, type: ["Mobile", "Player"] }), [actor]
        actor.output "The earth trembles beneath your feet!"
        ( targets = actor.target({ not: actor, list: actor.room.occupants })).each do |target|
            actor.deal_damage(target: target, damage: 100, noun:"earthquake", element: Constants::Element::GEOLOGY, type: Constants::Damage::MAGICAL)
        end
        return true
    end
end

class SpellEnchantWeapon < Spell

    def initialize(game)
        super(
            game: game,
            name: "enchant weapon",
            keywords: ["enchant weapon"],
            lag: 2,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def cast( actor, cmd, args )
    	if args.first.nil?
    		actor.output "Cast the spell on what now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args, level )
        if ( target = actor.target({ list: actor.inventory.items, item_type: "weapon" }.merge( args.first.to_s.to_query )).first )
            fail = 25
            # dam =
            affect = AffectEnchantWeapon.new( source: nil, target: target, level: actor.level, game: @game )
            affect.overwrite_modifiers({hitroll: level, damroll: 10})
            target.apply_affect( affect )
            return true
        else
            actor.output "You don't see that here."
            return false
        end
    end
end

class SpellEnergyDrain < Spell

    def initialize(game)
        super(
            game: game,
            name: "energy drain",
            keywords: ["energy drain"],
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
        actor.deal_damage(target: target, damage: 100, noun:"life drain", element: Constants::Element::NEGATIVE, type: Constants::Damage::MAGICAL)
        target.use_movement( 10 )
        target.output "You feel your energy slipping away!"
        actor.output "Wow....what a rush!"
        return true
    end
    
end