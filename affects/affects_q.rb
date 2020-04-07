require_relative 'affect.rb'

class AffectQuestItem < Affect
    def initialize(source, target, level)
        super(
                source, # source
                target, # target
                level, # level
                60 * 5, # duration
                nil, # modifiers: nil
                nil, # period: nil
                false, # permanent: false
                Visibility::PASSIVE, # visibility
                false # savable
            )
        areas = Game.instance.areas.values.select{ |area| area.questable == 1 && area.min < @target.level && area.max > @target.level }
        @room = areas.map{ |area| area.rooms }.flatten.sample
        @item = Game.instance.load_item( [2089,2090,2091].sample, @room.inventory )
        @completed = false
    end

    def start
        Game.instance.add_event_listener(@item, :event_calculate_aura_description, self, :do_quest_flag)
        Game.instance.add_event_listener(@target, :event_get_item, self, :do_quest)
        Game.instance.add_event_listener(@target, :event_complete_quest, self, :do_quest_complete)
    end

    def complete
        Game.instance.remove_event_listener(@item, :event_calculate_aura_description, self)
        Game.instance.remove_event_listener(@target, :event_get_item, self)
        Game.instance.remove_event_listener(@target, :event_complete_quest, self)
    end

    def do_quest_flag(data)
        if data[:observer] == @target
            data[:description] = "{C(QUEST){x " + data[:description]
        end
    end

    def send_start_messages
        @target.output Constants::Quests::Item::FIRST.sample % [ @item ]
        @target.output "You may begin your search in #{ @room.area } for #{ @room.name }!"
    end

    def send_complete_messages
        @target.output "{RYou may now quest again.{x"
    end

    def do_quest(data)
        if data[:actor] == @target && data[:item] == @item
            @completed = true
        else
            @target.output "Something is wrong... has someone else completed your quest?"
        end
    end

    def do_quest_complete(data)
        log("QUEST COMPLETED!")
        if @completed
            @target.output "You have completed your quest! Yay!"
            @target.xp( @target )
            @target.qp( @target )
            @target.remove_affect "quest"
        else
            @target.output "You aren't done yet."
        end
    end

    def self.affect_info
        return @info || @info = {
            name: "item quest",
            keywords: ["quest", "item quest"],
            application_type: :global_overwrite,
        }
    end
end

class AffectQuestVillain < Affect
    def initialize(source, target, level)
	    super(
	            source, # source
	            target, # target
	            level, # level
	            60 * 5, # duration
	            nil, # modifiers: nil
	            nil, # period: nil
	            false, # permanent: false
	            Visibility::PASSIVE, # visibility
	            false # savable
	        )
	    areas = Game.instance.areas.values.select{ |area| area.questable == 1 && area.min < @target.level && area.max > @target.level }
		@villain = areas.map(&:mobiles).flatten.select{ |mob| mob.level < @target.level + 5 && mob.level > @target.level - 5 }.sample
        @completed = false
	end

	def start
        Game.instance.add_event_listener(@villain, :event_calculate_aura_description, self, :do_quest_flag)
		Game.instance.add_event_listener(@villain, :event_on_die, self, :do_quest)
        Game.instance.add_event_listener(@target, :event_complete_quest, self, :do_quest_complete)
    end

    def complete
        Game.instance.remove_event_listener(@villain, :event_calculate_aura_description, self)
        Game.instance.remove_event_listener(@villain, :event_on_die, self)
        Game.instance.remove_event_listener(@target, :event_complete_quest, self)
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

    def do_quest(data)
        if data[:died] == @villain && data[:killer] == @target
        	@target.output "You have completed your quest! Yay!"
            @completed = true
        else
        	@target.output "Something is wrong... has someone else completed your quest?"
        	@target.remove_affect "quest"
        end
    end

    def do_quest_complete(data)
        if @completed
            @target.output "You have completed your quest! Yay!"
            @target.xp( @target )
            @target.qp( @target )
            @target.remove_affect "quest"
        else
            @target.output "You aren't done yet."
        end
    end

    def self.affect_info
        return @info || @info = {
            name: "villain quest",
            keywords: ["quest", "villain quest"],
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
            Visibility::PASSIVE, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "questmaster",
            keywords: ["questmaster"],
            application_type: :global_overwrite,
        }
    end

end
