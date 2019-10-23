require_relative 'skill.rb'

class SkillPaintPower < Skill

	@@slots = [ "torso", "head", "arms", "wrist_1", "wrist_2" ]

    def initialize(game)
        super(
            game: game,
            name: "paint power",
            keywords: ["paint"],
            lag: 0.25,
            position: Constants::Position::STAND,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input )
    	if ( slot = @@slots.select{ |s| s.fuzzy_match( args.first.to_s ) && actor.equipment[ s.to_sym ].nil? }.first )
    		tattoo = Tattoo.new( actor, slot )
    		actor.output "You carefully paint a magical tattoo on your #{ slot.gsub(/\_\d/, "") }."
    		actor.broadcast "%s carefully paints a magical tattoo on their #{ slot.gsub(/\_\d/, "") }.", actor.room.occupants - [actor], [actor]
    		actor.output "{YThe tattoo sparkles brilliantly!{x" if tattoo.brilliant
    		actor.output "You have painted the following tattoo: #{tattoo.lore}"
    		actor.equipment[ slot.to_sym ] = tattoo
            return true
    	else
    		actor.output "You don't have an empty equipment slot there."
            return false
    	end
    end
end

class SkillPeek < Skill

    def initialize(game)
        super(
            game: game,
            name: "peek",
            keywords: ["peek"],
            lag: 0.1,
            position: Constants::Position::REST,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            if target.inventory.count > 0
                actor.output "#{target} is carrying:\n#{target.inventory.items.map(&:to_s).join("\n")}"
                return true
            else
                actor.output "#{target} is carrying:\nNothing."
                return true
            end
        else
            actor.output "You cannot seem to catch a glimpse."
            return false
        end
    end

end