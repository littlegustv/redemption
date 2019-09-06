require_relative 'skill.rb'

class SkillDisarm < Command

    def initialize
        super()
        @name = "disarm"
        @keywords = ["disarm"]
        @lag = 2
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
        if not actor.attacking
        	actor.output "But you aren't fighting anyone!"
        elsif not actor.attacking.equipment[:wield]
        	actor.output "They aren't wielding a weapon."
        else
        	actor.output "You disard %s!", [actor.attacking]
        	actor.attacking.output "You have been disarmed!"
        	actor.broadcast "%s disarms %s", actor.target({ not: [ actor, actor.attacking ], room: actor.room }), [actor, actor.attacking]
        	actor.attacking.equipment[:wield].room = actor.room
        	actor.attacking.equipment[:wield] = nil
        end
    end
end
