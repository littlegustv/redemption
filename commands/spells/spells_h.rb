require_relative 'spell.rb'

class SpellHarm < Spell

    def initialize
        super(
            name: "harm",
            keywords: ["harm"],
            lag: 0.25,
            mana_cost: 50
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
        target.receive_damage(actor, 100, :harm)
        return true
    end
end

class SpellHaste < Spell

    def initialize
        super(
            name: "haste",
            keywords: ["haste"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        AffectHaste.new( actor, nil, level || actor.level ).apply
    end

end

class SpellHeal < Spell

    def initialize
        super(
            name: "heal",
            keywords: ["heal"],
            lag: 0.25,
            mana_cost: 10,
            priority: 13
        )
    end

    def attempt( actor, cmd, args, input, level )
        quantity = 100
        target = actor
        if !args.first.nil?
            target = actor.target( argument: args[0], list: actor.room.occupants ).first
        end
        if target
            target.output "You feel better!"
            target.regen( quantity, 0, 0 )
        else
            actor.output "They aren't here."
        end
    end

end

class SpellHeatMetal < Spell

    def initialize
        super(
            name: "heat metal",
            keywords: ["heat metal"],
            lag: 0.25,
            mana_cost: 5
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
        if args.first.nil? && actor.attacking
            target = actor.attacking
        elsif !args.first.nil?
            target = actor.target( argument: args[0], list: actor.room.occupants ).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end

        target.equipment.select{ |item| item.material.metallic }.each do | item |
            target.receive_damage(actor, 10, :fireball, false, true, "the scalding #{item.material} of #{item.name}")
        end
        return true
    end
end

class SpellHolyWord < Spell

    def initialize
        super(
            name: "holy word",
            keywords: ["holy word"],
            lag: 0.5,
            mana_cost: 25
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = actor
        if args.first
            target = actor.target( argument: args[0], list: actor.items + actor.room.occupants - [actor] ).first
        end
        if target
            target.output "A warm feeling runs through your body."
            target.regen 100, 0, 0
            AffectBless.new( target, nil, actor.level ).apply
            AffectFrenzy.new( target, nil, actor.level ).apply
        else
            actor.output "There is no one here with that name."
        end
    end

end

class SpellHurricane < Spell

    def initialize
        super(
            name: "hurricane",
            keywords: ["hurricane"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        (actor.room.occupants - [actor]).each_output "0<N> summons the power of a hurricane!", [actor]
        actor.output "You summon a hurricane!"
    	( targets = actor.target( list: actor.room.occupants - [actor] ) ).each do |target|
    		target.receive_damage(actor, 100, :hurricane)
    	end
        return true
    end
end

class SpellHypnosis < Spell

    def initialize
        super(
            name: "hypnosis",
            keywords: ["hypnosis"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target( argument: args[0], list: actor.room.occupants - [actor] ).first )
            actor.output "You hypnotize 0<n>", [target]
            target.output "0<N> hypnotizes you to '#{args.join(" ")}'", [actor]
            target.do_command args.join(" ")
        else
            actor.output "Order whom to do what?"
        end
    end
end
