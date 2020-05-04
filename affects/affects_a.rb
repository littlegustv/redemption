require_relative 'affect.rb'

class AffectAggressive < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            0, # level
            0, # duration
            nil, # modifiers
            nil, # period
            true, # permanent
            Visibility::HIDDEN, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "aggressive",
            keywords: ["aggressive"],
            application_type: :global_overwrite,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_observe_mobile_enter, self, :toggle_aggro)
        Game.instance.add_event_listener(@target, :event_mobile_enter, self, :toggle_aggro)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_observe_mobile_enter, self)
        Game.instance.remove_event_listener(@target, :event_mobile_enter, self)
    end

    def toggle_aggro(data)
        toggle_periodic(rand * 3)
    end

    def periodic
        if (players = @target.room.players).empty?
            # toggle_periodic(nil)
            return
        end
        player = players.select{ |t| @target.can_see?(t) }.shuffle!.first
        if player && !@target.attacking
            @target.room.occupants.each_output "0<N> scream0<,s> and attack0<,s>!!", [@target]
            @target.start_combat player
            @target.do_round_of_attacks(target: player)
        end
    end

end

class AffectAlarmRune < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            120, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "alarm rune",
            keywords: ["alarm rune", "rune"],
            application_type: :source_overwrite,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_calculate_room_description, self, :alarm_rune_description)
        Game.instance.add_event_listener(@target, :event_room_mobile_enter, self, :do_alarm_rune)
        Game.instance.add_event_listener(@source, :event_try_alarm_rune, self, :stop_alarm_rune)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_calculate_room_description, self)
        Game.instance.remove_event_listener(@target, :event_room_mobile_enter, self)
        Game.instance.remove_event_listener(@source, :event_try_alarm_rune, self)
    end

    def send_complete_messages
    	@source.output "Your connection with the alarm rune is broken."
    	@target.occupants.each_output "The rune of warding on this room vanishes."
    end

    def do_alarm_rune(data)
    	if data[:mobile] == @source
    		@source.output "You sense the power of the room's rune and avoid it!"
    	else
    		@source.output "{R0<N> has triggered your alarm rune!{x", [data[:mobile]]
	    end
    end

    def stop_alarm_rune(data)
        data[:success] = false
    end

    def alarm_rune_description(data)
        data[:extra_show] += "\nA rune is on the floor, glowing softly."
    end

end

class AffectAnimalGrowth < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            120, # duration
            {con: 3, str: 3}, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "animal growth",
            keywords: ["animal growth"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.room.occupants.each_output "0<N> 0<look,looks> like an animal.", @target
    end

    def send_complete_messages
        @target.room.occupants.each_output "0<N> no longer 0<look,looks> like an animal.", @target
    end
end

class AffectArmor < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            300, # duration
            { ac_pierce: 10, ac_slash: 10, ac_bash: 10, ac_magic: 10 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "armor",
            keywords: ["armor"],
            application_type: :source_overwrite,
        }
    end

    def send_start_messages
        @target.output "You feel someone protecting you."
    	(@target.room.occupants - [@target]).each_output "0<N> looks more protected.", [@target]
    end

    def send_complete_messages
        @target.output "You feel less armored."
    end

end
