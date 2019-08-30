require_relative 'command.rb'

class CommandRecall < Command

    def initialize
        super({
            keywords: ["recall", "/"],
            position: Position::STAND
        })
    end

    def attempt( actor, cmd, args )
        actor.recall
    end
end

class CommandRemove < Command

    def initialize
        super({
            keywords: ["remove"],
            position: Position::REST
        })
    end

    def attempt( actor, cmd, args )
        actor.unwear args
    end
end

class CommandRest < Command

    def initialize
        super({
            keywords: ["sit", "rest"],
            position: Position::SLEEP,
            usable_in_combat: false
        })
    end

    def attempt( actor, cmd, args )
        case actor.position
        when Position::SLEEP
            actor.output "You wake up and rest."
            actor.broadcast "%s wakes up and begins to rest.", actor.target( { :not => actor, :room => actor.room }), [actor]
            actor.position = Position::REST
            actor.look_room
        when Position::REST
            actor.output "You are already resting."
        when Position::STAND
            actor.output "You sit down and rest."
            actor.broadcast "%s sits down and rests.", actor.target( { :not => actor, :room => actor.room }), [actor]
            actor.position = Position::REST
        else
            actor.output "You can't quite get comfortable enough."
        end
    end
end
