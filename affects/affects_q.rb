require_relative 'affect.rb'

class AffectQuestItem < Affect
    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            60 * 5, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :passive, # visibility
            false # savable
        )
        areas = Game.instance.areas.values.select{ |area| area.questable && area.min < @target.level && area.max > @target.level }
        @room = areas.map{ |area| area.rooms }.flatten.sample
        @item = Game.instance.load_item( [2089,2090,2091].sample, @room.inventory )
        @completed = false
    end

    def start
        add_event_listener(@item, :event_calculate_long_auras, :do_quest_flag)
        add_event_listener(@target, :event_get_item, :do_quest)
        add_event_listener(@target, :event_complete_quest, :do_quest_complete)
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
        # log("QUEST COMPLETED!")
        if @completed
            @target.output "You have completed your quest! Yay!"
            @target.xp( @target )
            @target.qp( @target )
            @target.remove_affects_with_keywords "quest"
        else
            @target.output "You aren't done yet."
        end
    end

    def self.affect_info
        return @info || @info = {
            name: "quest item",
            keywords: ["quest", "quest item"],
            existing_affect_selection: :affect_id,
            application_type: :overwrite,
        }
    end
end

class AffectQuestVillain < Affect
    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            60 * 5, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :passive, # visibility
            false # savable
        )
	    areas = Game.instance.areas.values.select{ |area| area.questable && area.min < @target.level && area.max > @target.level }
		@villain = areas.map(&:mobiles).flatten.select{ |mob| mob.level < @target.level + 5 && mob.level > @target.level - 5 }.sample
        @completed = false
	end

	def start
        add_event_listener(@villain, :event_calculate_long_auras, :do_quest_flag)
		add_event_listener(@villain, :event_on_die, :do_quest)
        add_event_listener(@target, :event_complete_quest, :do_quest_complete)
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
        	@target.remove_affects_with_keywords "quest"
        end
    end

    def do_quest_complete(data)
        if @completed
            @target.output "You have completed your quest! Yay!"
            @target.xp( @target )
            @target.qp( @target )
            @target.remove_affects_with_keywords "quest"
        else
            @target.output "You aren't done yet."
        end
    end

    def self.affect_info
        return @info || @info = {
            name: "quest villain",
            keywords: ["quest", "quest villain"],
            existing_affect_selection: :affect_id,
            application_type: :overwrite,
        }
    end
end

class AffectQuestMaster < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            :passive, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "questmaster",
            keywords: ["questmaster"],
            existing_affect_selection: :affect_id,
            application_type: :overwrite,
        }
    end

end
