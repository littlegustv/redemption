require_relative 'spell.rb'

class SpellDeathRune < Spell

    def initialize(game)
        super(
            game: game,
            name: "death rune",
            keywords: ["death rune"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectDeathRune.new( source: actor, target: actor, level: level, game: @game ) )
    end

end

class SpellDemonFire < Spell

    def initialize(game)
        super(
            game: game,
            name: "demonfire",
            keywords: ["demonfire"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args, input )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
            return
        else
            super
        end
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if actor.alignment > -100
            target = actor
        elsif args.first.nil? && actor.attacking
            target = actor.attacking
        elsif !args.first.nil?
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end

        if !target
            actor.output "They aren't here."
            return false
        end

        if target == actor
            actor.output "The demons turn upon you!"
        else
            actor.output "You conjure forth the demons of hell!"
            target.output "%s has assailed you with the demons of Hell!", [actor]
        end

        actor.broadcast "%s calls forth the demons of Hell upon %s!", actor.room.occupants - [target, actor], [actor, target]
        
        actor.deal_damage(target: target, damage: 100, noun:"torments", element: Constants::Element::NEGATIVE, type: Constants::Damage::MAGICAL)
        actor.alignment = [ actor.alignment - 50, -1000 ].max

        target.apply_affect( AffectCurse.new( source: nil, target: target, level: actor.level, game: @game ))

        return true
    end
end

class SpellDestroyRune < Spell

    def initialize(game)
        super(
            game: game,
            name: "destroy rune",
            keywords: ["destroy rune"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
    	if args.first.nil?
    		if actor.room.affected? "rune"
                actor.room.remove_affect( "rune" )
                actor.broadcast "The runes present in this room begin fade.", actor.room.occupants
                return true
            else
                actor.output "There are no runes found."
                return false
            end
    	elsif ( target = actor.target({ list: actor.equipment + actor.inventory, item_type: "weapon" }.merge( args.first.to_s.to_query )).first )
    		if target.affected?("rune")
    			actor.output "The runes on %s slowly fade out of existence.", [target]
    			target.remove_affect( "rune" )
                return true
            else
                actor.output "%s is not runed.", [target]
                return false
    		end
    	end
    end
end

class SpellDestroyTattoo < Spell

    def initialize(game)
        super(
            game: game,
            name: "destroy tattoo",
            keywords: ["destroy tattoo"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args, input )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on what now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args, input, level )
    	if ( target = actor.target({ list: actor.equipment, type: "tattoo" }.merge( args.first.to_s.to_query )).first )
    		actor.output "You focus your will and #{target} explodes into flames!"
    		target.destroy true
            return true
        else
            actor.output "You don't have a tattoo like that."
            return false
    	end
    end
end

class SpellDetectInvisibility < Spell

    def initialize(game)
        super(
            game: game,
            name: "detect invisibility",
            keywords: ["detect invisibility"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectDetectInvisibility.new( source: actor, target: actor, level: level, game: @game ) )
    end

end

class SpellDetectMagic < Spell

    def initialize(game)
        super(
            game: game,
            name: "detect magic",
            keywords: ["detect magic"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            actor.output target.show_affects(observer: actor)
            return true
        else
            actor.output "There is no one here with that name."
            return false
        end
    end
end

class SpellDispelMagic < Spell

    def initialize(game)
        super(
            game: game,
            name: "dispel magic",
            keywords: ["dispel magic"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            target.remove_affect( actor.affects.sample.keywords.first ) if target.affects.count > 0
            return true
        else
            actor.output "There is no one here with that name."
            return false
        end
    end

end