require_relative 'spell.rb'

class SpellPyrotechnics < Spell

    def initialize(game)
        super(
            game: game,
            name: "pyrotechnics",
            keywords: ["pyrotechnics"],
            lag: 0.25,
            position: Position::STAND
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
    	if args.first.nil? && actor.attacking
    		actor.magic_hit( actor.attacking, 100, "pyrotechnics", "flaming" )
            return true
    	elsif ( target = actor.target({ room: actor.room, type: ["Mobile", "Player"] }.merge( args.first.to_s.to_query )).first )
    		actor.magic_hit( target, 100, "pyrotechnics", "flaming" )
            return true
    	else
    		actor.output "They aren't here."
            return false
    	end
    end
end

class SpellPhantomForce < Spell

    def initialize(game)
        super(
            game: game,
            name: "phantom force",
            keywords: ["phantom force"],
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
        if args.first.nil? && actor.attacking
            actor.magic_hit( actor.attacking, 100, "ghoulish grasp", "frost" )
            return true
        elsif ( target = actor.target({ room: actor.room, type: ["Mobile", "Player"] }.merge( args.first.to_s.to_query )).first )
            actor.magic_hit( target, 100, "ghoulish grasp", "frost" )
            return true
        else
            actor.output "They aren't here."
            return false
        end
    end
end