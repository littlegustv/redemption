require_relative 'spell.rb'

class SpellHarm < Spell

    def initialize
        super(
            name: "harm",
            keywords: ["harm"],
            lag: 0.25,
            position: Constants::Position::STAND,
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.deal_damage(target: target, damage: 100, noun:"harm", element: Constants::Element::HOLY, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellHeal < Spell

    def initialize
        super(
            name: "heal",
            keywords: ["heal"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 13
        )
    end

    def attempt( actor, cmd, args, input, level )
        quantity = 100
        target = actor
        if !args.first.nil?
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
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
            position: Constants::Position::STAND,
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end

        target.equipment.select{ |item| Constants::Materials::METAL.include? item.material }.each do | item |
            actor.deal_damage(target: target, damage: 10, noun: "scalding #{item.material}", element: Constants::Element::FIRE, type: Constants::Damage::MAGICAL)
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
            position: Constants::Position::STAND,
            mana_cost: 25
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = actor
        if args.first
            target = Game.instance.target({ list: actor.items + actor.room.occupants - [actor] }.merge( args.first.to_s.to_query )).first
        end
        if target
            target.output "A warm feeling runs through your body."
            target.regen 100, 0, 0
            target.apply_affect( AffectBless.new( nil, target, actor.level ) )
            target.apply_affect( AffectFrenzy.new( nil, target, actor.level ) )
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
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        (actor.room.occupants - [actor]).each_output "0<N> summons the power of a hurricane!", [actor]
        actor.output "You summon a hurricane!"
    	( targets = actor.target({ not: actor, list: actor.room.occupants })).each do |target|
    		actor.deal_damage(target: target, damage: 100, noun:"hurricane", element: Constants::Element::DROWNING, type: Constants::Damage::MAGICAL)
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
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target({ list: actor.room.occupants, not: actor, visible_to: actor }.merge( args.shift.to_s.to_query ) ).first )
            actor.output "You hypnotize 0<n>", [target]
            target.output "0<N> hypnotizes you to '#{args.join(" ")}'", [actor]
            target.do_command args.join(" ")
        else
            actor.output "Order whom to do what?"
        end
    end
end
