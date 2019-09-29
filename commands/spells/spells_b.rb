require_relative 'spell.rb'

class SpellBlastOfRot < Spell

    def initialize(game)
        super(
            game: game,
            name: "blast of rot",
            keywords: ["blast", "rot", "blast of rot"],
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
    	if args.first.nil? && actor.attacking
    		actor.magic_hit( actor.attacking, 100, "blast of rot", "poison" )
            return true
    	elsif ( target = actor.target({ room: actor.room, type: ["Mobile", "Player"] }.merge( args.first.to_s.to_query )).first )
    		actor.magic_hit( target, 100, "blast of rot", "poison" )
            return true
    	else
    		actor.output "They aren't here."
            return false
    	end
    end
end

class SpellBurstRune < Spell

    def initialize(game)
        super(
            game: game,
            name: "burst rune",
            keywords: ["burst rune"],
            lag: 0.25,
            position: Position::STAND
        )
    end

    def cast( actor, cmd, args )
        if args.first.nil?
            actor.output "Cast the spell on what now?"
            return
        else
            super
        end
    end

    def attempt( actor, cmd, args, level )
        if ( target = actor.target({ list: actor.inventory.items + actor.equipment, item_type: "weapon" }.merge( args.first.to_s.to_query )).first )
            if target.affected? "burst rune"
                actor.output "The existing burst rune repels your magic."
                return false
            else
                target.apply_affect( AffectBurstRune.new( source: actor, target: target, level: actor.level, game: @game ) )
                return true
            end
        else
            actor.output "You don't see that here."
            return false
        end
    end

end

class SpellBladeRune < Spell

    def initialize(game)
        super(
            game: game,
            name: "blade rune",
            keywords: ["blade rune"],
            lag: 0.25,
            position: Position::STAND
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
        if ( target = actor.target({ list: actor.inventory.items + actor.equipment, item_type: "weapon" }.merge( args.first.to_s.to_query )).first )
            if target.affected? "blade rune"
                actor.output "The existing blade rune repels your magic."
                return false
            else
                target.apply_affect( AffectBladeRune.new( source: actor, target: target, level: actor.level, game: @game ) )
                return true
            end
        else
            actor.output "You don't see that here."
            return false
        end
    end
end
