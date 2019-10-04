require_relative 'spell.rb'

class SpellPhantasmMonster < Spell

    def initialize(game)
        super(
            game: game,
            name: "phantasm monster",
            keywords: ["phantasm monster"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, level )
        actor.output "You call forth phantasmic forces!"
        mob = @game.load_mob( 1844, actor.room )
        @game.mobiles.push mob
        mob.apply_affect( AffectFollow.new( source: actor, target: mob, level: 1, game: @game ) )
        mob.apply_affect( AffectCharm.new( source: actor, target: mob, level: actor.level, game: @game ) )
    end

end

class SpellPhantomForce < Spell

    def initialize(game)
        super(
            game: game,
            name: "phantom force",
            keywords: ["phantom force"],
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.deal_damage(target: target, damage: 100, noun:"ghoulish grasp", element: Constants::Element::COLD, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellPlague < Spell

    def initialize(game)
        super(
            game: game,
            name: "plague",
            keywords: ["plague"],
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        target.apply_affect( AffectPlague.new( source: actor, target: target, level: actor.level, game: @game ) )
        target.start_combat( actor )
        return true
    end

end

class SpellPoison < Spell

    def initialize(game)
        super(
            game: game,
            name: "poison",
            keywords: ["poison"],
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        target.apply_affect( AffectPoison.new( source: actor, target: target, level: actor.level, game: @game ) )
        target.start_combat( actor )
        return true
    end
end

class SpellProtection < Spell

    def initialize(game)
        super(
            game: game,
            name: "protection",
            keywords: ["protection"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, level )
        if args.first.to_s.fuzzy_match("good")
            actor.apply_affect( AffectProtectionGood.new( source: nil, target: actor, level: actor.level, game: @game ) )
        elsif args.first.to_s.fuzzy_match("neutral")
            actor.apply_affect( AffectProtectionNeutral.new( source: nil, target: actor, level: actor.level, game: @game ) )
        elsif args.first.to_s.fuzzy_match("evil")
            actor.apply_affect( AffectProtectionEvil.new( source: nil, target: actor, level: actor.level, game: @game ) )
        end
    end

end

class SpellPyrotechnics < Spell

    def initialize(game)
        super(
            game: game,
            name: "pyrotechnics",
            keywords: ["pyrotechnics"],
            lag: 0.25,
            position: Position::STAND
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.deal_damage(target: target, damage: 100, noun:"pyrotechnics", element: Constants::Element::FIRE, type: Constants::Damage::MAGICAL)
        return true
    end
end
