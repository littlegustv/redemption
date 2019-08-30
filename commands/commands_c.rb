require_relative 'command.rb'

class CommandConsider < Command

    def initialize
        @keywords = ["consider"]
        @priority = 100
        @lag = 0
        @position = Position::REST
    end

    def attempt( actor, cmd, args )
        if ( target = actor.target({ room: actor.room, keyword: args.first.to_s, type: ["Mobile"], visible_to: actor }).first )
            case  target.level - actor.level
            when -51..-10
                actor.output "You can kill #{target} naked and weaponless."
            when -9..-5
                actor.output "#{target} is no match for you."
            when -6..-2
                actor.output "#{target} looks like an easy kill."
            when -1..1
                actor.output "The perfect match!"
            when 2..4
                actor.output "#{target} says 'Do you feel lucky, punk?'."
            when 5..9
                actor.output "#{target} laughs at you mercilessly."
            else
                actor.output "Death will thank you for your gift.";
            end
        end
    end

end
