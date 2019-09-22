require_relative 'spell.rb'

class SpellAcidBlast < Spell

    def initialize(game)
        super(
            game: game,
            name: "acid blast",
            keywords: ["acid", "blast", "acid blast"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on who, now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args )
    	if args.first.nil? && actor.attacking
    		actor.magic_hit( actor.attacking, 100, "acid blast", "corrosive" )
    	elsif ( target = actor.target({ room: actor.room, type: ["Mobile", "Player"] }.merge( args.first.to_s.to_query )).first )
    		actor.magic_hit( target, 100, "acid blast", "corrosive" )
    	else
    		actor.output "They aren't here."
    	end
    end
end

class SpellAlarmRune < Spell

    def initialize(game)
        super(
            game: game,
            name: "alarm rune",
            keywords: ["alarm rune"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args )
        if actor.affected? "alarm rune"
            actor.output "You already sense others."
        elsif actor.room.affected? "alarm rune"
            actor.output "This room is already being sensed."
        else
            actor.output "You place an alarm rune on the ground, increasing your senses."
            actor.broadcast "%s places a strange rune on the ground.", actor.target({ room: actor.room, not: actor }), [actor]
            actor.room.apply_affect( AffectAlarmRune.new( source: actor, target: actor.room, level: actor.level, game: @game ) )
            actor.apply_affect( Affect.new( name: "alarm rune", keywords: [], source: actor, target: actor, level: actor.level, duration: 10, modifiers: { none: 0 }, game: @game ) )
        end
    end
end
