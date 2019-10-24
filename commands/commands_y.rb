require_relative 'command.rb'

class CommandYell < Command

    def initialize(game)
        super(
            game: game,
            name: "yell",
            keywords: ["yell"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if args.length <= 0
            actor.output 'Yell what?'
            return false
        else
            message = input[/#{cmd} (.*)/, 1]
            
            data = { text: message }
            @game.fire_event( actor, :event_communicate, data )
            message = data[:text]

            actor.output "{RYou yell '#{message}'{x"
            actor.broadcast "{R%s yells '#{message}'{x", actor.room.area.players - [actor], [actor]
            return true
        end
    end
end
