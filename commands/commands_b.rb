require_relative 'command.rb'

class CommandBerserk < Command

    def initialize
        @keywords = ["berserk"]
        @priority = 100
        @lag = 0.5
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
        if not actor.affected? "berserk"
            actor.affects.push AffectBerserk.new( actor, ["berserk"], 60, { damroll: 10, hitroll: 10 }, 1 )
        else
            actor.output "You are already pretty mad."
        end
    end
end

class CommandBlind < Command

    def initialize
        @keywords = ["blind"]
        @priority = 100
        @lag = 0.5
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
        if not actor.affected? "blind"
            actor.output "You have been blinded!"
            actor.affects.push( AffectBlind.new( actor, ["blind"], 30, { hitroll: -5 } ) )
        else
            actor.output "You are already blind!"
        end
    end
end
