require_relative 'spell.rb'

class SpellIceBolt < Spell

    def initialize
        super(
            name: "ice bolt",
            keywords: ["ice bolt"],
            lag: 0.25,
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
            target = actor.target( argument: args[0], list: actor.room.occupants ).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        target.receive_damage(actor, 100, :ice_blast)
        return true
    end
end

class SpellIgnoreWounds < Spell
    def initialize
        super(
            name: "ignore wounds",
            keywords: ["ignore wounds"],
            lag: 0.25,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        AffectIgnoreWounds.new( actor, nil, level ).apply
    end
end

class SpellInfravision < Spell
    def initialize
        super(
            name: "infravision",
            keywords: ["infravision"],
            lag: 0.25,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if args.first.nil?
            target = actor
        elsif !(target = actor.target( argument: args[0], list: actor.room.occupants + actor.items ).first)
            actor.output "You don't see anything like that here."
            return false
        end
        AffectInfravision.new( target, actor, level ).apply
        return true
    end
end

class SpellInvisibility < Spell
    def initialize
        super(
            name: "invisibility",
            keywords: ["invisibility"],
            lag: 0.25,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if args.first.nil?
            target = actor
        elsif !(target = actor.target( list: actor.room.occupants + actor.items, argument: args.first).first)
            actor.output "You don't see anything like that here."
            return false
        end
        AffectInvisibility.new( target, actor, level ).apply
        return true
    end
end
