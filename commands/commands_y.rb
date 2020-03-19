require_relative 'command.rb'

class CommandYell < Command

    def initialize
        super(
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
            Game.instance.fire_event( actor, :event_communicate, data )
            message = data[:text]

            actor.room.area.occupants.each_output "{R0<N> yell0<,s> '#{message}'{x", [actor]
            return true
        end
    end
end
