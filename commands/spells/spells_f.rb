require_relative 'spell.rb'

class SpellFireRune < Spell

    def initialize(game)
        super(
            game: game,
            name: "fire rune",
            keywords: ["fire rune"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args )
    	if actor.room.affected? "fire rune"
    		actor.output "This room is already affected by the power of flames."
    	else
    		actor.output "You place a fiery rune on the ground to singe your foes."
    		actor.broadcast "%s places a strange rune on the ground.", actor.target({ room: actor.room, not: actor }), [actor]
    		actor.room.apply_affect( AffectFireRune.new( source: actor, target: actor.room, level: actor.level, game: @game ) )
    	end
    end
end
