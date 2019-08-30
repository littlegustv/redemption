require_relative 'command.rb'

class CommandYell < Command

    def initialize
        @keywords = ["yell"]
        @priority = 100
        @lag = 0
        @position = Position::REST
    end

    def attempt( actor, cmd, args )
        if args.length <= 0
            actor.output 'Yell what?'
        else
            actor.output "{RYou yell '#{args.join(' ')}'{x"
            actor.broadcast "{R%s yells '#{args.join(' ')}'{x", actor.target( { :not => actor, :area => actor.room.area }), [actor]
        end
    end
end
