require_relative 'spell.rb'

class SpellKnowAlignment < Spell

    def initialize(game)
        super(
            game: game,
            name: "know alignment",
            keywords: ["know alignment"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, level )
        if ( target = @game.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query ) ).first )
        	actor.output Constants::ALIGNMENT_DESCRIPTIONS.select{ |key, value| target.alignment >= key }.values.last, [target]
        else
        	actor.output "They aren't here."
        end
    end

end