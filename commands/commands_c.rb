require_relative 'command.rb'

class CommandConsider < Command

    def initialize
        super()

        @keywords = ["consider"]
        @position = Position::REST
    end

    def attempt( actor, cmd, args )
        if ( target = actor.target({ room: actor.room, type: ["Mobile"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
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
        else
            actor.output "You don't see anyone like that here."
        end
    end

end
