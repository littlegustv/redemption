require_relative 'command.rb'

class CommandRecall < Command

    def initialize
        super(
            name: "recall",
            keywords: ["recall", "/"],
            position: :standing
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
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        if ( targets = actor.target( argument: args[0], list: actor.equipment ) )
            targets.each do |target|
                actor.unwear(target)
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
            position: :sleeping,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input )
        if actor.position == :sleeping
            data = { success: true }
            Game.instance.fire_event( actor, :try_wake, data )
            if data[:success]
                actor.output "You wake up and rest."
                (actor.room.occupants - [actor]).each_output "0<N> wakes up and begins to rest.", [actor]
                actor.position = :resting.to_position
                actor.look_room
                return true
            else
                actor.output "You can't wake up!"
                return false
            end
        elsif actor.position == :resting
            actor.output "You are already resting."
            return false
        elsif actor.position == :standing
            actor.output "You sit down and rest."
            (actor.room.occupants - [actor]).each_output "0<N> sits down and rests.", [actor]
            actor.position = :resting.to_position
            return true
        else
            actor.output "You can't quite get comfortable enough."
            return false
        end
    end
end
