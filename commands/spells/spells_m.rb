require_relative 'spell.rb'

class SpellMagicMissile < Spell

    def initialize
        super(
            name: "magic missile",
            keywords: ["magic missile"],
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
        level.times do |i|
            actor.deal_damage(target: target, damage: 20, noun:"magic missile", element: Constants::Element::ENERGY, type: Constants::Damage::MAGICAL)
        end
        return true
    end
end

class SpellManaDrain < Spell

    def initialize
        super(
            name: "mana drain",
            keywords: ["mana drain"],
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
        target.use_mana( 10 )
        actor.regen( 0, 10, 0 )
        target.output "You feel your energy slipping away!"
        actor.output "Wow....what a rush!"
        return true
    end
end

class SpellMassHealing < Spell

    def initialize
        super(
            name: "mass healing",
            keywords: ["mass healing"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 13
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
        actor.target({ list: actor.room.occupants, visible_to: actor, not: actor.attacking }).reject{ |occ| occ.attacking == actor }.each do |occupant|
            occupant.output "You feel less tired."
            occupant.output "You feel better!"
            occupant.regen( 100, 0, 50 )
        end
    end

end

class SpellMassInvisibility < Spell
    def initialize
        super(
            name: "mass invisibility",
            keywords: ["mass invisibility"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        ( targets = Game.instance.target( args.first.to_s.to_query.merge({ list: actor.room.occupants, visible_to: actor }) ) ).each do |target|
            target.apply_affect( AffectInvisibility.new( actor, target, level ) )
        end
    end
end

class SpellMinimation < Spell
    def initialize
        super(
            name: "minimation",
            keywords: ["minimation"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectMinimation.new( nil, actor, actor.level ) )
    end
end

class SpellMirrorImage < Spell
    def initialize
        super(
            name: "mirror image",
            keywords: ["mirror image"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectMirrorImage.new( actor, actor, level ) )
    end
end
