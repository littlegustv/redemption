require_relative 'spell.rb'

class SpellAcidBlast < Spell

    def initialize
        super(
            name: "acid blast",
            keywords: ["acid", "blast", "acid blast"],
            lag: 0.25,
            mana_cost: 10
        )
        @damage_formula = Formula.new("(1+level/8)d(10+level/25)+15")
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
        if args.first.nil? && actor.attacking
            target = actor.attacking
        elsif !args.first.nil?
            target = actor.target( argument: args[0], list: actor.room.occupants ).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        damage = @damage_formula.evaluate(actor)
        target.receive_damage(actor, damage, :acid_blast)
        return true
    end
end

class SpellAlarmRune < Spell

    def initialize
        super(
            name: "alarm rune",
            keywords: ["alarm rune"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        data = {success: true}
        Game.instance.fire_event(actor, :try_alarm_rune, data)
        if !data[:success]
            actor.output "You already sense others."
            return false
        elsif actor.room.affected? "alarm rune"
            actor.output "This room is already being sensed."
            return false
        else
            actor.output "You place an alarm rune on the ground, increasing your senses."
            (actor.room.occupants - [actor]).each_output "0<N> places a strange rune on the ground.", [actor]
            AffectAlarmRune.new( actor.room, actor, actor.level ).apply
            return true
        end
    end
end

class SpellAnimalGrowth < Spell


    def initialize
        super(
            name: "animal growth",
            keywords: ["animal growth"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        AffectAnimalGrowth.new( actor, actor, level || actor.level ).apply
    end

end

class SpellArmor < Spell


    def initialize
        super(
            name: "armor",
            keywords: ["armor"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        AffectArmor.new( actor, actor, actor.level ).apply
    end

end
