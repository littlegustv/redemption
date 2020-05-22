require_relative 'spell.rb'

class SpellOracle < Spell

    def initialize
        super(
            name: "oracle",
            keywords: ["oracle"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if actor.room.affected? "oracle"
        	actor.output "There already is an oracle in this room."
        else
        	actor.room.occupants.each_output "0<N> 0<,has> create0<,ed> an oracle of benefit.", [actor]
        	AffectOracle.new( actor, actor.room, actor.level ).apply
        end
    end
end