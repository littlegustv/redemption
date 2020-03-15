require_relative 'affect.rb'

class AffectQuest < Affect
    def initialize(source, target, level)
	    super(
	            source, # source
	            target, # target
	            level, # level
	            60 * 5, # duration
	            nil, # modifiers: nil
	            nil, # period: nil
	            false, # permanent: false
	            Constants::AffectVisibility::PASSIVE, # visibility
	            false # savable
	        )
	    areas = Game.instance.areas.values.select{ |area| area.questable == 1 && area.min < @target.level && area.max > @target.level }
		@villain = areas.map(&:mobiles).flatten.select{ |mob| mob.level < @target.level + 5 && mob.level > @target.level - 5 }.sample
	end

	def start
        Game.instance.add_event_listener(@villain, :event_calculate_aura_description, self, :do_quest_flag)
		Game.instance.add_event_listener(@villain, :event_on_die, self, :do_villain_quest)
    end

    def complete
        Game.instance.remove_event_listener(@villain, :event_calculate_aura_description, self)
        Game.instance.remove_event_listener(@villain, :event_on_die, self)
    end

    def do_quest_flag(data)
    	if data[:observer] == @target
	        data[:description] = "{C(QUEST){x " + data[:description]
	    end
    end

    def send_start_messages
    	@target.output Constants::Quests::Villain::FIRST.sample % [ @villain ]
        @target.output Constants::Quests::Villain::SECOND.sample % [ @villain, rand(2..20) ]
        @target.output Constants::Quests::Villain::THIRD.sample % [ @villain ]
        @target.output "Seek #{ @villain } out somewhere in the vicinity of #{ @villain.room.name }!"
        @target.output "You can find that location in #{ @villain.room.area }."
    end

    def send_complete_messages
    	@target.output "{RYou may now quest again.{x"
    end

    def do_villain_quest(data)
        if data[:died] == @villain && data[:killer] == @target
        	@target.output "You have completed your quest! Yay!"
        	@target.xp( @villain )
        	@target.remove_affect "quest"
        else
        	@target.output "Something is wrong... has someone else completed your quest?"
        	@target.remove_affect "quest"
        end
    end

    def self.affect_info
        return @info || @info = {
            name: "quest",
            keywords: ["quest"],
            application_type: :global_overwrite,
        }
    end
end

class AffectQuestMaster < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            Constants::AffectVisibility::PASSIVE, # visibility
            true # savable
        )
        log("Applying questmaster #{source} #{source.room}")
    end

    def self.affect_info
        return @info || @info = {
            name: "questmaster",
            keywords: ["questmaster"],
            application_type: :global_overwrite,
        }
    end

end