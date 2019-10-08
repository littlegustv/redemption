require_relative 'spell.rb'

class SpellManaDrain < Spell

    def initialize(game)
        super(
            game: game,
            name: "mana drain",
            keywords: ["mana drain"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args )
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
        target.output "You feel your energy slipping away!"
        actor.output "Wow....what a rush!"
        return true
    end
end

class SpellMassInvisibility < Spell
    def initialize(game)
        super(
            game: game,
            name: "mass invisibility",
            keywords: ["mass invisibility"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, input, level )
        ( targets = @game.target( args.first.to_s.to_query.merge({ list: actor.room.occupants, visible_to: actor }) ) ).each do |target|
            target.apply_affect( AffectInvisibility.new( source: actor, target: target, level: level, game: @game ) )
        end
    end
end

class SpellMirrorImage < Spell
    def initialize(game)
        super(
            game: game,
            name: "mirror image",
            keywords: ["mirror image"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 5,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectMirrorImage.new( source: actor, target: actor, level: level, game: @game ) )
    end
end