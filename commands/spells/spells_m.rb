require_relative 'spell.rb'

class SpellMassInvisibility < Spell
    def initialize(game)
        super(
            game: game,
            name: "mass invisibility",
            keywords: ["mass invisibility"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 5
        )
    end

    def attempt( actor, cmd, args, level )
        ( targets = @game.target( args.first.to_s.to_query.merge({ list: actor.room.occupants, visible_to: actor, quantity: "all" }) ) ).each do |target|
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
            position: Position::STAND,
            mana_cost: 5,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, level )
        actor.apply_affect( AffectMirrorImage.new( source: actor, target: actor, level: level, game: @game ) )
    end
end