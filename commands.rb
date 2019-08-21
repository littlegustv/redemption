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
        actor.output ""
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
        targets = actor.target( { type: "Player", visible_to: actor } )
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
            actor.output "{yYou say '#{args.join(' ')}'{x"
            actor.broadcast "{y%s says '#{args.join(' ')}'{x", actor.target( { :not => actor, :room => actor.room }), [actor]
        end
    end
end

class Yell < Command
    def attempt( actor, args )
        if args.length <= 0
            actor.output 'Yell what?'
        else
            actor.output "{rYou yell '#{args.join(' ')}'{x"
            actor.broadcast "{r%s yells '#{args.join(' ')}'{x", actor.target( { :not => actor, :area => actor.room.area }), [actor]
        end
    end
end

class Kill < Command
    def attempt( actor, args )
        if actor.position < Position::STAND
            actor.output "You have to stand up first."
        elsif actor.position >= Position::FIGHT
            actor.output "You are already fighting!"
        elsif ( kill_target = actor.target({ room: actor.room, not: actor, keyword: args.first.to_s, type: ["Mobile", "Player"], visible_to: actor }).first )
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
            actor.broadcast "%s has fled!", actor.target({ room: actor.room }), [ actor ]
            actor.stop_combat
            actor.do_command(actor.room.exits.select{ |k, v| not v.nil? }.keys.sample.to_s)
        else
            actor.output "PANIC! You couldn't escape!"
        end
    end
end

class Peek < Command
    def attempt( actor, args )
        if ( target = actor.target({ room: actor.room, keyword: args.first.to_s, type: ["Mobile"], visible_to: actor }).first )
            if target.inventory.count > 0
                actor.output "#{target} is carrying:\n#{target.inventory.map(&:to_s).join("\n")}"
            else
                actor.output "#{target} is carrying:\nNothing."
            end            
        else
            actor.output "You cannot seem to catch a glimpse."
        end
    end
end

class Get < Command
    def attempt( actor, args )
        if ( target = actor.target({ room: actor.room, keyword: args.first.to_s, type: ["Item", "Weapon"], visible_to: actor }).first )
            target.room = nil
            actor.inventory.push target
            actor.output "You get #{ target }."
            actor.broadcast "%s gets %s.", actor.target({ not: actor, room: actor.room, type: "Player" }), [actor, target]
        else
            actor.output "You don't see that here."
        end
    end
end

class Drop < Command
    def attempt( actor, args )
        if ( target = actor.inventory.select { |item| item.fuzzy_match( args.first.to_s ) && actor.can_see?(item) }.first )
            target.room = actor.room
            actor.inventory.delete target
            actor.output "You drop #{target}."
            actor.broadcast "%s drops %s.", actor.target({ not: actor, room: actor.room, type: "Player" }), [actor, target]
        else
            actor.output "You don't have that."
        end
    end
end

class Inventory < Command
    def attempt( actor, args )
        actor.output %Q(
Inventory:
#{ actor.inventory.map{ |i| "#{ actor.can_see?(i) ? i.to_s : i.to_someone }" }.join("\n") }
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
#{ actor.equipment.map { |key, value| "<worn on #{key}> #{ value.nil? ? "Nothing" : ( actor.can_see?(value) ? value.to_s : value.to_someone ) }" }.join("\n") }
        )
    end
end

class Blind < Command
    def attempt( actor, args )
        actor.output "You have been blinded!"
        actor.affects.push "blind"
    end
end

class Unblind < Command
    def attempt( actor, args )
        actor.output "You can now see again."
        actor.affects.delete "blind"
    end
end
