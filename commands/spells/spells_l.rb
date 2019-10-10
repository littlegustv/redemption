require_relative 'spell.rb'

class SpellLightningBolt < Spell

    def initialize(game)
        super(
            game: game,
            name: "lightning bolt",
            keywords: ["lightning bolt"],
            lag: 0.25,
            position: Constants::Position::STAND
        )
    end

    def cast( actor, cmd, args, input )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on who, now?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if args.first.nil? && actor.attacking
            target = actor.attacking
        elsif !args.first.nil?
            target = actor.target({ list: actor.room.occupants }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.deal_damage(target: target, damage: 100, noun:"lightning bolt", element: Constants::Element::LIGHTNING, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellLocateObject < Spell

    def initialize(game)
        super(
            game: game,
            name: "locate object",
            keywords: ["locate object"],
            lag: 0.25,
            position: Constants::Position::STAND
        )
    end

    def cast( actor, cmd, args, input )
    	if args.first.nil?
    		actor.output "What did you want to locate?"
    	else
	    	super
	    end
    end

    def attempt( actor, cmd, args, input, level )
        before = Time.now
        targets = @game.target({type: "Item", visible_to: actor}.merge(args.first.to_s.to_query) )
        after = Time.now
        log "{rlocate{x #{after - before}"
        # puts targets
        if !targets
            actor.output "Nothing like that in heaven or earth."
            return false
        end
        # actor.deal_damage(target: target, damage: 100, noun:"lightning bolt", element: Constants::Element::LIGHTNING, type: Constants::Damage::MAGICAL)
        return true
    end
end
