require_relative 'spell.rb'

class SpellShackleRune < Spell

    def initialize(game)
        super(
            game: game,
            name: "shackle rune",
            keywords: ["shackle rune"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, level )
    	if actor.room.affected? "shackle rune"
    		actor.output "This room is already affected by the restriction of movement."
            return false
    	else
    		actor.output "You place a shackle on the ground preventing easy movement."
    		actor.broadcast "%s places a strange rune on the ground.", actor.target({ list: actor.room.occupants, not: actor }), [actor]
    		actor.room.apply_affect( AffectShackleRune.new( source: actor, target: actor.room, level: actor.level, game: @game ) )
            return true
    	end
    end
end
