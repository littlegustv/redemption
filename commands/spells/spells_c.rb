require_relative 'spell.rb'

class SpellCalm < Spell

    def initialize
        super(
            name: "calm",
            keywords: ["calm"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.room.occupants.each do | entity |
            entity.output "A wave of calm washes over you."
            (entity.room.occupants - [entity]).each_output "0<N> calms down and loses the will to fight.", [entity]
            entity.remove_affect "berserk"
            entity.remove_affect "frenzy"
            entity.remove_affect "taunt"
            entity.stop_combat
            entity.apply_affect( AffectCalm.new( nil, entity, actor.level ) )
        end
    end

end

class SpellCancellation < Spell

    def initialize
        super(
            name: "cancellation",
            keywords: ["cancellation"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.remove_affect( actor.affects.sample.keywords.first ) if actor.affects.count > 0
    end

end

class SpellCauseLight < Spell

    def initialize
        super(
            name: "cause light",
            keywords: ["cause light"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
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
        actor.deal_damage(target: target, damage: 25, noun:"cause light wounds", element: Constants::Element::HOLY, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellCauseSerious < Spell

    def initialize
        super(
            name: "cause serious",
            keywords: ["cause serious"],
            lag: 0.25,
            position: Constants::Position::STAND,
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.deal_damage(target: target, damage: 50, noun:"cause serious wounds", element: Constants::Element::HOLY, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellCauseCritical < Spell

    def initialize
        super(
            name: "cause critical",
            keywords: ["cause critical"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 25
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
        actor.deal_damage(target: target, damage: 75, noun:"cause critical wounds", element: Constants::Element::HOLY, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellChainLightning < Spell

    def initialize
        super(
            name: "chain lightning",
            keywords: ["chain lightning"],
            lag: 0.5,
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
            target = actor.target({ list: actor.room.occupants }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.room.occupants.each_output "A lightning bolt leaps from 0<n>'s hand and arcs to 1<n>1<!,.>", [actor, target]

        damage = 100
        actor.deal_damage(target: target, damage: damage, noun:"lightning bolt", element: Constants::Element::LIGHTNING, type: Constants::Damage::MAGICAL)
        while (damage -= 10) >= 0
            target = actor.room.occupants.sample # TODO: target only combatable mobs?

            if target == actor
                (actor.room.occupants - [actor]).each_output "The bolt arcs to 0<n>... whoops!", [actor]
                actor.output "You are struck by your own lightning!"
            else
                actor.room.occupants.each_output "The bolt arcs to 0<n>!", [target]
            end

            actor.deal_damage(target: target, damage: damage, noun:"lightning bolt", element: Constants::Element::LIGHTNING, type: Constants::Damage::MAGICAL)
        end

        (actor.room.occupants - [target]).each_output "The bolt seems to have fizzled out."
        target.output "The bolt grounds out through your body."

        return true
    end
end

class SpellCharmPerson < Spell

    def initialize
        super(
            name: "charm person",
            keywords: ["charm person"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = Game.instance.target( { list: actor.room.occupants - [actor], visible_to: actor }.merge( args.first.to_s.to_query ) ).first )
            if rand(1..10) <= 5
                actor.output "0<N> looks at you with adoring eyes.", [target]
                target.output "Isn't 0<n> just so nice??", [actor]
                target.apply_affect( AffectFollow.new( actor, target, 1 ) )
                target.apply_affect( AffectCharm.new( actor, target, actor.level ) )
            else
                actor.output "You failed."
                target.start_combat( actor )
            end
        else
            actor.output "There is no one here with that name."
        end
    end

end

class SpellCloakOfMind < Spell

    def initialize
        super(
            name: "cloak of mind",
            keywords: ["cloak of mind"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectCloakOfMind.new( nil, actor, actor.level ) )
    end

end

class SpellCloudkill < Spell

    def initialize
        super(
            name: "cloudkill",
            keywords: ["cloudkill"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.room.apply_affect( AffectCloudkill.new( actor, actor.room, actor.level ) )
    end

end

class SpellColorSpray < Spell

    def initialize
        super(
            name: "colour spray",
            keywords: ["color spray", "colour spray"],
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
        actor.deal_damage(target: target, damage: 50, noun:"color spray", element: Constants::Element::LIGHT, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellContinualLight < Spell

    def initialize
        super(
            name: "continual light",
            keywords: ["continual light"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        if args.first.nil?
            item = Game.instance.load_item( 1952, actor.inventory )
            actor.room.occupants.each_output "0<N> twiddles 0<p> thumbs and 1<n> appears.", [actor, item]
        elsif ( target = Game.instance.target( { list: actor.items + actor.room.items, visible_to: actor }.merge( args.first.to_s.to_query ) ).first )
            target.apply_affect( AffectGlowing.new( nil, target, actor.level ))
        else
            actor.output "You don't see that here."
        end
    end
end

class SpellFloatingDisc < Spell

    def initialize
        super(
            name: "floating disc",
            keywords: ["floating disc"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        if actor.free?("wear_float")
            actor.output "You create a floating disc."
            (actor.room.occupants - [actor]).each_output "0<N> has created a floating black disc.", [actor]
            disc = Game.instance.load_item( 1954, actor.inventory )
            actor.wear( item: disc )
            return true
        else
            actor.output "Your airspace is too crowded for any more entities."
            return false
        end
    end

end

class SpellCreateFood < Spell

    def initialize
        super(
            name: "create food",
            keywords: ["create food"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        food = Game.instance.load_item( 1951, actor.room.inventory )
        actor.room.occupants.each_output "0<N> suddenly appears.", [food]
    end

end

class SpellCreateRose < Spell

    def initialize
        super(
            name: "create rose",
            keywords: ["create rose"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        rose = Game.instance.load_item( 846, actor.room.inventory )
        actor.output "You create 0<n>.", [rose]
        (actor.room.occupants - [actor]).each_output "0<N> has conjured 1<n>.", [actor, rose]
    end

end

class SpellCreateSpring < Spell

    def initialize
        super(
            name: "create spring",
            keywords: ["create spring"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        spring = Game.instance.load_item( 1953, actor.room.inventory )
        actor.room.occupants.each_output "0<N> flows from the ground.", [spring]
    end

end

class SpellCureBlindness < Spell

    def initialize
        super(
            name: "cure blindness",
            keywords: ["cure blindness"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 14
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = args.first.nil? ? actor : actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        if target
            if target.affected? "blind"
                target.output "Your vision returns!"
                target.remove_affect "blind"
            else
                actor.output "They aren't blind."
            end
        else
            actor.output "They aren't here."
        end
    end
end

class SpellCureCritical < Spell

    def initialize
        super(
            name: "cure critical",
            keywords: ["cure critical"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 12
        )
    end

    def attempt( actor, cmd, args, input, level )
        quantity = 50
        if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            target.output "You feel better!"
            target.regen( quantity, 0, 0 )
        elsif args.first.nil?
            actor.output "You feel better"
            actor.regen( quantity, 0, 0 )
        else
            actor.output "They aren't here."
        end
    end
end

class SpellCureDisease < Spell

    def initialize
        super(
            name: "cure disease",
            keywords: ["cure disease"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 15
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = args.first.nil? ? actor : actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        if target
            if target.affected? "plague"
                target.output "You feel better!"
                target.remove_affect "plague"
            else
                actor.output "They aren't infected."
            end
        else
            actor.output "They aren't here."
        end
    end
end

class SpellCureLight < Spell

    def initialize
        super(
            name: "cure light",
            keywords: ["cure light"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        quantity = 10
        if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            target.output "You feel better!"
            target.regen( quantity, 0, 0 )
        elsif args.first.nil?
            actor.output "You feel better"
            actor.regen( quantity, 0, 0 )
        else
            actor.output "They aren't here."
        end
    end
end

class SpellCurePoison < Spell

    def initialize
        super(
            name: "cure poison",
            keywords: ["cure poison"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 14
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = args.first.nil? ? actor : actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        if target
            if target.affected? "poison"
                target.output "You feel better!"
                target.remove_affect "poison"
            else
                actor.output "They aren't poisoned."
            end
        else
            actor.output "They aren't here."
        end
    end
end

class SpellCureSerious < Spell

    def initialize
        super(
            name: "cure serious",
            keywords: ["cure serious"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 11
        )
    end

    def attempt( actor, cmd, args, input, level )
        quantity = 25
        if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            target.output "You feel better!"
            target.regen( quantity, 0, 0 )
        elsif args.first.nil?
            actor.output "You feel better"
            actor.regen( quantity, 0, 0 )
        else
            actor.output "They aren't here."
        end
    end
end

class SpellCurse < Spell

    def initialize
        super(
            name: "curse",
            keywords: ["curse"],
            lag: 0.25,
            position: Constants::Position::STAND,
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        target.apply_affect( AffectCurse.new( actor, target, actor.level ) )
        target.start_combat( actor )
        return true
    end

end
