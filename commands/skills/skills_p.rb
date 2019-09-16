require_relative 'skill.rb'

class SkillPaintPower < Skill

	@@slots = [ "torso", "head", "arms", "wrist_1", "wrist_2" ]
    
    def initialize
        super()
        @name = "paint power"
        @keywords = ["paint"]
        @lag = 0.25
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
    	if ( slot = @@slots.select{ |s| s.fuzzy_match( args.first.to_s ) && actor.equipment[ s.to_sym ].nil? }.first )
    		tattoo = Tattoo.new( actor, slot )
    		actor.output "You carefully paint a magical tattoo on your #{ slot.gsub(/\_\d/, "") }."
    		actor.broadcast "%s carefully paints a magical tattoo on their #{ slot.gsub(/\_\d/, "") }.", actor.target({ room: actor.room, quantity: "all", not: actor }), [actor]
    		actor.output "{YThe tattoo sparkles brilliantly!{x" if tattoo.brilliant
    		actor.output "You have painted the following tattoo: #{tattoo.lore}"
    		actor.equipment[ slot.to_sym ] = tattoo
    	else
    		actor.output "You don't have an empty equipment slot there."
    	end
    end
end
