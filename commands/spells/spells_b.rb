require_relative 'spell.rb'

class SpellBlastOfRot < Spell

    def initialize
        super()
        @name = "blast of rot"
        @keywords = ["blast", "rot", "blast of rot"]
        @lag = 0.25
        @position = Position::STAND
    end

    def cast( actor, cmd, args )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on who, now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args )
    	if args.first.nil? && actor.attacking
    		actor.magic_hit( actor.attacking, 100, "blast of rot", "poison" )
    	elsif ( target = actor.target({ not: actor, room: actor.room, type: ["Mobile", "Player"] }.merge( args.first.to_s.to_query )).first )
    		actor.magic_hit( target, 100, "blast of rot", "poison" )
    	else
    		actor.output "They aren't here."
    	end
    end
end

class SpellBurstRune < Spell

    def initialize
        super()
        @name = "burst rune"
        @keywords = ["burst rune"]
        @lag = 0.25
        @position = Position::STAND
    end

    def cast( actor, cmd, args )
        if args.first.nil?
            actor.output "Cast the spell on what now?"
        else
            super
        end
    end

    def attempt( actor, cmd, args )
        if ( target = actor.target({ list: actor.inventory + actor.equipment.values.reject(&:nil?), item_type: "weapon" }.merge( args.first.to_s.to_query )).first )
            if target.affected? "burst rune"
                actor.output "The existing burst rune repels your magic."
            else
                target.apply_affect( AffectBurstRune.new( source: actor, target: target, level: actor.level ) )
            end
        else
            actor.output "You don't see that here."
        end
    end

end

class SpellBladeRune < Spell

    def initialize
        super()
        @name = "blade rune"
        @keywords = ["blade rune"]
        @lag = 0.25
        @position = Position::STAND
    end

    def cast( actor, cmd, args )
        if args.first.nil?
            actor.output "Cast the spell on what now?"
        else
            super
        end
    end

    def attempt( actor, cmd, args )
        if ( target = actor.target({ list: actor.inventory + actor.equipment.values.reject(&:nil?), item_type: "weapon" }.merge( args.first.to_s.to_query )).first )
            if target.affected? "blade rune"
                actor.output "The existing blade rune repels your magic."
            else
                target.apply_affect( AffectBladeRune.new( source: actor, target: target, level: actor.level ) )
            end
        else
            actor.output "You don't see that here."
        end
    end
end