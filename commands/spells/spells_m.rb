require_relative 'spell.rb'

class SpellMagicMissile < Spell

    def initialize
        super(
            name: "magic missile",
            keywords: ["magic missile"],
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        level.times do |i|
            target.receive_damage(actor, 20, :magic_missile)
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
            target = actor.target( argument: args[0], list: actor.room.occupants ).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        target.receive_damage(actor, 100, :life_drain)
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
        actor.target( argument: args[0], list: actor.room.occupants ).reject{ |occ| occ.attacking == actor }.each do |occupant|
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
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        ( targets = actor.target( list: actor.room.occupants ) ).each do |target|
            AffectInvisibility.new( target, nil, level ).apply
        end
    end
end

class SpellMinimation < Spell
    def initialize
        super(
            name: "minimation",
            keywords: ["minimation"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        AffectMinimation.new( actor, nil, actor.level ).apply
    end
end

class SpellMirrorImage < Spell
    def initialize
        super(
            name: "mirror image",
            keywords: ["mirror image"],
            lag: 0.25,
            mana_cost: 5,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input, level )
        AffectMirrorImage.new( actor, nil, level ).apply
    end
end
