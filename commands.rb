class Command

    def initialize( keywords, lag = 0, position = Position::STAND )
        @keywords = keywords
        @lag = lag
        @position = position
    end

    def check( cmd )
        @keywords.select{ |keyword| keyword.fuzzy_match( cmd ) }.any?
    end

    def execute( actor, args )
        attempt( actor, args )
        actor.lag = @lag
    end

    def attempt( actor, args )
        actor.output "Default command"
    end

end

class Down < Command
    def attempt( actor, args )
        actor.move "down"
    end
end

class Up < Command
    def attempt( actor, args )
        actor.move "up"
    end
end

class East < Command
    def attempt( actor, args )
        actor.move "east"
    end
end

class West < Command
    def attempt( actor, args )
        actor.move "west"
    end
end

class North < Command
    def attempt( actor, args )
        actor.move "north"
    end
end

class South < Command
    def attempt( actor, args )
        actor.move "south"
    end
end

class Who < Command
    def attempt( actor, args )
        targets = actor.target( { type: "Player" } )
        actor.output %Q(
Players Online:
#{ targets.map{ |p| "[51 Troll    Runist] [  Loner  ] #{ p } the Master of Runes" }.join("\n") }
        )
    end
end

class Help < Command
    def attempt( actor, args )
        actor.output "Helpfiles don't really exist yet."
    end
end

class Qui < Command
    def attempt( actor, args )
        actor.output "If you want to QUIT, you'll have to spell it out."
    end
end

class Quit < Command
    def attempt( actor, args )
        actor.quit
    end
end

class Look < Command
    def attempt( actor, args )
        actor.output actor.room.show( actor )
    end
end

class Say < Command
    def attempt( actor, args )
        if args.length <= 0
            actor.output 'Say what?'
        else
            actor.output "You say '#{args.join(' ')}'"
            actor.broadcast "#{ actor } says '#{args.join(' ')}'", actor.target( { :not => actor, :room => actor.room } )
        end
    end
end

class Kill < Command
    def attempt( actor, args )
        if actor.position < Position::STAND
            actor.output "You have to stand up first."
        elsif actor.position >= Position::FIGHT
            actor.output "You are already fighting!"
        elsif ( kill_target = actor.target({ room: actor.room, not: actor, keyword: args.first.to_s, type: ["Mobile", "Player"] }).first )
            actor.start_combat kill_target
            kill_target.start_combat actor
        else
            actor.output "I can't find anyone with that name #{args}"
        end
    end
end

class Flee < Command
    def attempt( actor, args )
        if actor.position < Position::FIGHT
            actor.output "But you aren't fighting anyone!"
        elsif rand(0..10) < 5
            actor.output "You flee from combat!"
            actor.broadcast "#{ actor } has fled!", actor.target({ room: actor.room })
            actor.stop_combat
            actor.do_command(actor.room.exits.select{ |k, v| not v.nil? }.keys.sample.to_s)
        else
            actor.output "PANIC! You couldn't escape!"
        end
    end
end

class Get < Command
    def attempt( actor, args )
        if ( target = actor.target({ room: actor.room, keyword: args.first.to_s, type: ["Item", "Weapon"] }).first )
            target.room = nil
            actor.inventory.push target
            actor.output "You get #{ target }."
            actor.broadcast "#{ actor } gets #{target }.", actor.target({ not: actor, room: actor.room, type: "Player" })
        else
            actor.output "You don't see that here."
        end
    end
end

class Drop < Command
    def attempt( actor, args )
        if ( target = actor.inventory.select { |item| item.fuzzy_match( args.first.to_s ) }.first )
            target.room = actor.room
            actor.inventory.delete target
            actor.output "You drop #{target}."
            actor.broadcast "#{actor} drops #{target}.", actor.target({ not: actor, room: actor.room, type: "Player" })
        else
            actor.output "You don't have that."
        end
    end
end

class Inventory < Command
    def attempt( actor, args )
        actor.output %Q(
Inventory:
#{ actor.inventory.map{ |i| "#{i}" }.join("\n") }
        )
    end
end

class Wear < Command
    def attempt( actor, args )
        actor.wear args
    end
end

class Remove < Command
    def attempt( actor, args )
        actor.unwear args
    end
end

class Equipment < Command
    def attempt( actor, args )
        actor.output %Q(
Equipment
#{ actor.equipment.map { |key, value| "<worn on #{key}> #{value}" }.join("\n") }
        )
    end
end