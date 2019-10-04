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

class SpellShield < Spell


    def initialize(game)
        super(
            game: game,
            name: "shield",
            keywords: ["shield", "shield"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, level )
        actor.apply_affect( AffectShield.new( source: nil, target: actor, level: actor.level, game: @game ) )
    end

end

class SpellSlow < Spell

    def initialize(game)
        super(
            game: game,
            name: "slow",
            keywords: ["slow"],
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

    def attempt( actor, cmd, args, level )
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
        target.apply_affect( AffectSlow.new( source: actor, target: target, level: actor.level, game: @game ) )
        target.start_combat( actor )
        return true
    end
    
end

class SpellStoneSkin < Spell

    def initialize(game)
        super(
            game: game,
            name: "stoneskin",
            keywords: ["stone skin", "stoneskin"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, level )
        actor.apply_affect( AffectStoneSkin.new( source: nil, target: actor, level: actor.level, game: @game ) )
    end

end

class SpellSummon < Spell

    def initialize(game)
        super(
            game: game,
            name: "summon",
            keywords: ["summon"],
            lag: 0.25,
            position: Position::STAND,
            mana_cost: 25
        )
    end

    def attempt( actor, cmd, args, level )
        if ( target = @game.target({ type: ["Mobile", "Player"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
            @game.broadcast "%s disappears suddenly.", @game.target({ list: target.room.occupants }), [target]
            @game.broadcast "%s arrives suddenly.", @game.target({ list: actor.room.occupants }), [target]
            target.move_to_room actor.room
            target.output "%s has summoned you!", [actor]
        else
            actor.output "You can't find anyone with that name."
        end
    end

end