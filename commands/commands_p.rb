require_relative 'command.rb'

class CommandPoison < Command

    def initialize
        super(
            name: "poison",
            keywords: ["poison"],
            position: Constants::Position::STAND
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
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args, input )
        report = MemoryProfiler.stop
        puts report.pretty_print
    end

end

class CommandPry < Command

    def initialize
        super(
            name: "pry",
            keywords: ["pry"],
            position: Constants::Position::STAND
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
            position: Constants::Position::REST
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
