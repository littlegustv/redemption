require_relative 'command.rb'

class CommandRecall < Command

    def initialize(game)
        super(
            game: game,
            name: "recall",
            keywords: ["recall", "/"],
            position: Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        return actor.recall
    end
end

class CommandRemove < Command

    def initialize(game)
        super(
            game: game,
            name: "remove",
            keywords: ["remove"],
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        if ( targets = actor.target({ visible_to: actor, list: actor.equipment }.merge( args.first.to_s.to_query(1) )) )
            targets.each do |target|
                actor.unwear(item: target)
            end
            return true
        else
            actor.output "You aren't wearing that."
            return false
        end
    end
end

class CommandRest < Command

    def initialize(game)
        super(
            game: game,
            name: "rest",
            keywords: ["sit", "rest"],
            position: Position::SLEEP,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args )
        case actor.position
        when Position::SLEEP
            actor.output "You wake up and rest."
            actor.broadcast "%s wakes up and begins to rest.", actor.target( { :not => actor, :room => actor.room }), [actor]
            actor.position = Position::REST
            actor.look_room
            return true
        when Position::REST
            actor.output "You are already resting."
            return false
        when Position::STAND
            actor.output "You sit down and rest."
            actor.broadcast "%s sits down and rests.", actor.target( { :not => actor, :room => actor.room }), [actor]
            actor.position = Position::REST
            return true
        else
            actor.output "You can't quite get comfortable enough."
            return false
        end
    end
end
