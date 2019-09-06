require_relative 'command.rb'

class CommandFlee < Command

    def initialize
        super()

        @keywords = ["flee"]
        @lag = 0.5
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
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
