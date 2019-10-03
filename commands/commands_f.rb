require_relative 'command.rb'

class CommandFlee < Command

    def initialize(game)
        super(
            game: game,
            name: "flee",
            keywords: ["flee"],
            lag: 0.5,
            position: Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        if !actor.attacking
            actor.output "But you aren't fighting anyone!"
            return false
        elsif rand(0..10) < 5
            actor.output "You flee from combat!"
            actor.broadcast "%s has fled!", actor.target({ not: actor, list: actor.room.occupants }), [ actor ]
            actor.stop_combat
            actor.do_command(actor.room.exits.select{ |k, v| not v.nil? }.keys.sample.to_s)
            return true
        else
            actor.output "PANIC! You couldn't escape!"
            return true
        end
    end
end
