require_relative 'command.rb'

class CommandKill < Command

    def initialize
        super(
            name: "kill",
            keywords: ["kill", "hit"],
            lag: 0.5,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        keyword_used = @keywords.to_s.split.find{ |keyword| keyword.fuzzy_match( cmd.split(" ").first ) }
        if args.length <= 0
            actor.output "Who did you want to #{keyword_used}?"
            return false
        end
        if actor.attacking
            actor.output "You are already fighting!"
            return false
        elsif ( kill_target = actor.target( argument: args[0], list: actor.room.occupants - [actor] ).first )
            kill_target.start_combat(actor)
            actor.do_round_of_attacks
            return true
        else
            actor.output "I can't find anyone with that name."
            return false
        end
    end
end
