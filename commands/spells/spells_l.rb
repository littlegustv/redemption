require_relative 'spell.rb'

class SpellLightningBolt < Spell

    def initialize
        super(
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

    def initialize
        super(
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
        targets = []
        if actor.can_see?(nil)
            targets = Game.instance.target_global_items(args.first.to_s.to_query).shuffle
            total_found = targets.size
            targets = actor.filter_visible_targets(targets, 10)
        end
        if targets.length == 0
            actor.output "Nothing like that in heaven or earth."
            return false
        end
        out = targets.map{ |t| "%s is #{t.carrier.carried_by_string} %s." }.join("\n")
        out += "\n\nYour focus breaks before revealing all of the objects." if targets.length < total_found
        objects = targets.map{ |t| [t, t.carrier] }.flatten
        actor.output(out, objects)
        return true
    end
end
