require_relative 'skill.rb'

class SkillPaintPower < Skill

	@@slots = [ "torso", "head", "arms", "wrist_1", "wrist_2" ]

    def initialize
        super(
            name: "paint power",
            keywords: ["paint"],
            lag: 0.25,
            position: :standing,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input )
    	if ( slot = @@slots.find{ |s| s.fuzzy_match( args.first.to_s ) && actor.equipment[ s.to_sym ].nil? } )
    		tattoo = Tattoo.new( actor, slot )
    		actor.room.occupants.each_output "0<N> carefully paint0<,s> a magical tattoo on 0<p> #{ slot.gsub(/\_\d/, "") }.", [actor]
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

    def initialize
        super(
            name: "peek",
            keywords: ["peek"],
            lag: 0.1,
            position: :resting,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            if target.inventory.count > 0
                actor.output "0<N> is carrying:\n#{target.inventory.items.map(&:to_s).join("\n")}", [target]
                return true
            else
                actor.output "0<N> is carrying:\nNothing.", [target]
                return true
            end
        else
            actor.output "You cannot seem to catch a glimpse."
            return false
        end
    end

end

class SkillPickLock < Skill

    def initialize
        super(
            name: "pick lock",
            keywords: ["pick lock"],
            lag: 0.25,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = Game.instance.target( { list: actor.room.exits }.merge( args.first.to_s.to_query ) ).first )
            if rand(0...10) < 5
                return target.unlock( actor, override: true )
            else
                actor.output "You failed."
                return false
            end
        else
            actor.output "There is no exit in that direction."
            return false
        end
    end
end
