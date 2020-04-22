require_relative 'spell.rb'

class SpellKarma < Spell

    def initialize
        super(
            name: "karma",
            keywords: ["karma"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        AffectKarma.new( nil, actor, actor.level ).apply
    end

end

class SpellKnowAlignment < Spell

    def initialize
        super(
            name: "know alignment",
            keywords: ["know alignment"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = Game.instance.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query ) ).first )
        	actor.output Constants::ALIGNMENT_DESCRIPTIONS.select{ |key, value| target.alignment >= key }.values.last, [target]
        else
        	actor.output "They aren't here."
        end
    end

end
