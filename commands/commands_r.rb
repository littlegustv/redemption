require_relative 'command.rb'

class CommandRecall < Command

    def initialize
        super(
            name: "recall",
            keywords: ["recall", "/"],
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args, input )
        return actor.recall
    end
end

class CommandRemove < Command

    def initialize
        super(
            name: "remove",
            keywords: ["remove"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
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

    def initialize
        super(
            name: "rest",
            keywords: ["sit", "rest"],
            position: Constants::Position::SLEEP,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input )
        case actor.position
        when Constants::Position::SLEEP
            data = { success: true }
            Game.instance.fire_event( actor, :event_try_wake, data )
            if data[:success]
                actor.output "You wake up and rest."
                (actor.room.occupants - [actor]).each_output "0<N> wakes up and begins to rest.", [actor]
                actor.position = Constants::Position::REST
                actor.look_room
                return true
            else
                actor.output "You can't wake up!"
                return false
            end
        when Constants::Position::REST
            actor.output "You are already resting."
            return false
        when Constants::Position::STAND
            actor.output "You sit down and rest."
            (actor.room.occupants - [actor]).each_output "0<N> sits down and rests.", [actor]
            actor.position = Constants::Position::REST
            return true
        else
            actor.output "You can't quite get comfortable enough."
            return false
        end
    end
end
