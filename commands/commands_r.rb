require_relative 'command.rb'

class CommandRecall < Command

    def initialize
        @keywords = ["recall", "/"]
        @priority = 100
        @lag = 0
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
        actor.recall
    end
end

class CommandRemove < Command

    def initialize
        @keywords = ["remove"]
        @priority = 100
        @lag = 0
        @position = Position::REST
    end

    def attempt( actor, cmd, args )
        actor.unwear args
    end
end

class CommandRest < Command

    def initialize
        @keywords = ["sit", "rest"]
        @priority = 100
        @lag = 0
        @position = Position::SLEEP
    end

    def attempt( actor, cmd, args )
        case actor.position
        when Position::SLEEP
            actor.output "You wake up and rest."
            actor.broadcast "%s wakes up and begins to rest.", actor.target( { :not => actor, :room => actor.room }), [actor]
        when Position::REST
            actor.output "You are already resting."
        when Position::STAND
            actor.output "You sit down and rest."
            actor.broadcast "%s sits down and rests.", actor.target( { :not => actor, :room => actor.room }), [actor]
        else
            actor.output "You can't quite get comfortable enough."
        end
        actor.position = Position::REST
    end
end
