require_relative 'command.rb'

class CommandKill < Command

    def initialize

        super({
            keywords: ["kill", "hit"],
            lag: 0.5,
            starts_combat: true,
            usable_while_fighting: false,
            position: Position::STAND,
        })
    end

    def attempt( actor, cmd, args )
        if actor.position < Position::STAND
            actor.output "You have to stand up first."
        elsif actor.position >= Position::FIGHT
            actor.output "You are already fighting!"
        elsif ( kill_target = actor.target({ room: actor.room, not: actor, keyword: args.first.to_s, type: ["Mobile", "Player"], visible_to: actor }).first )
            actor.start_combat kill_target
            kill_target.start_combat actor
        else
            actor.output "I can't find anyone with that name."
        end
    end
end
