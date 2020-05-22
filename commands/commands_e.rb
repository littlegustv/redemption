require_relative 'command.rb'

class CommandEat < Command

    def initialize
        super(
            name: "eat",
            keywords: ["eat"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = actor.target({ list: actor.items, item_type: Pill, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            actor.room.occupants.each_output "0<N> 0<eat,eats> 1<n>.", [actor, target]
            target.consume( actor )
        else
            actor.output("You don't see that here.")
        end
    end

end

class CommandEmote < Command

    def initialize
        super(
            name: "emote",
            keywords: ["emote"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        if args.length <= 0
            actor.output 'Emote what?'
            return false
        else
            message = input[/#{cmd} (.*)/, 1]
            actor.room.occupants.each_output "0<N> #{message}", [actor]
            return true
        end
    end

end

class CommandEnter < Command

    def initialize
        super(
            name: "enter",
            keywords: ["enter"],
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if args.first.nil?
            actor.output "Enter what?"
            return
        end
        if ( target = Game.instance.target({ list: actor.room.items }.merge( args.first.to_s.to_query )).first )
            if !target.is_a?(Portal)
                actor.output "You can't enter that."
                return false
            elsif target.exit
                target.exit.move(actor)
                return true
            end
        else
            actor.output "You don't see that here."
        end
    end
end

class CommandEquipment < Command

    def initialize
        super(
            name: "equipment",
            keywords: ["equipment"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        actor.output "You are using:"
        actor.show_equipment(actor)
        return true
    end
end
