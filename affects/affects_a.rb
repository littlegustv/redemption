require_relative 'affect.rb'

class AffectAggressive < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            0, # level
            0, # duration
            nil, # modifiers
            1, # period
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
        add_event_listener(@target, :event_observe_mobile_enter, :toggle_aggro)
        add_event_listener(@target, :event_mobile_enter, :toggle_aggro)
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
            @target.do_round_of_attacks(player)
        end
    end

end

class AffectAlarmRune < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
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
        add_event_listener(@target, :event_calculate_room_description, :alarm_rune_description)
        add_event_listener(@target, :event_room_mobile_enter, :do_alarm_rune)
        add_event_listener(@source, :event_try_alarm_rune, :stop_alarm_rune)
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

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            120, # duration
            {
                constitution: 3,
                strength: 3
            }, # modifiers: nil
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

class AffectAnoint < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
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
            name: "anoint",
            keywords: ["anoint"],
            application_type: :global_single,
        }
    end

    def start
        add_event_listener(@target, :event_on_deal_damage, :do_lifesteal)
        add_event_listener(@target, :event_calculate_receive_damage, :do_amplify)
    end

    def send_start_messages
        @target.room.occupants.each_output "0<N> 0<prepare,prepares> 0<p> for some good work.", @target
    end

    def send_complete_messages
        @target.room.occupants.each_output "0<N> 0<are/is> no longer so actively holy.", @target
    end

    def do_lifesteal( data )
        @target.regen( data[:damage] * 0.1, 0, 0 )
    end

    def do_amplify( data )
        data[:damage] *= 1.1
    end
end

class AffectArmor < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            300, # duration
            { armor_class: -20 }, # modifiers: nil
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
