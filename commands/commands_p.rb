require_relative 'command.rb'

class CommandPeer < Command

    def initialize
        super(
            name: "peer",
            keywords: ["peer"],
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if args.first.to_s == ""
            actor.output "Peer in which direction?"
        elsif ( direction = actor.room.exits.select{ |k, v| k.to_s.fuzzy_match( args.first.to_s ) && !v.nil? }.keys.first )
            actor.output "You peer #{direction}."
            actor.output actor.room.exits[ direction ].destination.show( actor )
        else
            actor.output "There is no room in that direction."
        end
    end

end

class CommandPoison < Command

    def initialize
        super(
            name: "poison",
            keywords: ["poison"],
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if not actor.affected? "poison"
            actor.apply_affect(AffectPoison.new( actor, actor, actor.level ))
            return true
        else
            actor.output "You are already poisoned."
            return false
        end
    end

end

class CommandProfile < Command

    def initialize
        super(
            name: "profile",
            keywords: ["profile"],
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        # report = MemoryProfiler.stop
        # puts report.pretty_print
    end

end

class CommandPry < Command

    def initialize
        super(
            name: "pry",
            keywords: ["pry"],
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        binding.pry
    end

end

class CommandPut < Command

    def initialize
        super(
            name: "put",
            keywords: ["put"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        if args.dig(1) == "in"
            args[1] = args.dig(2)
        end
        if !args.dig(0)
            actor.output "Put what where?"
            return false
        elsif !args.dig(1)
            actor.output "Where did you want to put it?"
            return false
        end
        container = actor.target({ list: actor.items + actor.room.items, visible_to: actor }.merge(args[1].to_s.to_query)).first
        targets = actor.target({ not: container, list: actor.items, visible_to: actor }.merge(args[0].to_s.to_query(1)))
        if targets.size == 0
            actor.output "You don't have anything like that."
            return false
        elsif !container
            actor.output "You don't see that container here."
            return false
        elsif !(Container === container)
            actor.output "That's not a container."
            return false
        end
        targets.each do |t|
            actor.put_item(t, container)
        end
        return true
    end

end
