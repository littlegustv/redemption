require_relative 'spell.rb'

class SpellLightningBolt < Spell

    def initialize
        super(
            name: "lightning bolt",
            keywords: ["lightning bolt"],
            lag: 0.25
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
            target = actor.target( argument: args[0], list: actor.room.occupants ).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        target.receive_damage(actor, 100, :lightning_bolt)
        return true
    end
end

class SpellLocateObject < Spell

    def initialize
        super(
            name: "locate object",
            keywords: ["locate object"],
            lag: 0.25
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
        out = targets.each_with_index.map{ |t, i| "#{i*2}<N> is #{t.carrier.carried_by_string} #{i*2+1}<n>." }.join("\n")
        out += "\n\nYour focus breaks before revealing all of the objects." if targets.length < total_found
        objects = targets.map{ |t| [t, t.carrier] }.flatten
        actor.output(out, objects)
        return true
    end
end
