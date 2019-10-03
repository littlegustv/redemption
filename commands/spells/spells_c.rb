require_relative 'spell.rb'

class SpellCloakOfMind < Spell

    def initialize(game)
        super(
            game: game,
            name: "cloak of mind",
            keywords: ["cloak of mind"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, level )
        actor.apply_affect( AffectCloakOfMind.new( source: nil, target: actor, level: actor.level, game: @game ) )
    end

end