require_relative 'command.rb'

class CommandFlee < Command

    def initialize(game)
        super(
            game: game,
            name: "flee",
            keywords: ["flee"],
            lag: 0.5,
            position: Constants::Position::STAND
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

class CommandFollow < Command

    def initialize(game)
        super(
            game: game,
            name: "follow",
            keywords: ["follow"],
            lag: 0,
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        if args.first.nil?
            actor.remove_affect("follow")
        elsif ( target = actor.target({ list: actor.room.occupants, not: actor }.merge( args.first.to_s.to_query )).first )
            actor.apply_affect( AffectFollow.new( source: target, target: actor, level: 1, game: @game ) )
        else
            actor.output "They aren't here"
        end
    end
end
