require_relative 'affect.rb'

class AffectIgnoreWounds < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "ignore wounds",
            keywords: ["ignore wounds"],
            existing_affect_selection: :affect_id,
            application_type: :overwrite,
        }
    end

    def start
        add_event_listener(@target, :override_receive_damage, :do_ignore_wounds)
    end

    def send_start_messages
        @target.room.occupants.each_output "0<N> close0<,s> 0<p> eyes and forget0<,s> about the pain.", [@target]
    end

    def end_complete_messages
        @target.output "Your body is once again vulnerable."
    end

    def do_ignore_wounds(data)
        source = data[:source]
        if source && data[:confirm] == false && @target.attacking != source && rand(1..100) <= 50
            @target.output "You ignore the wounds inflicted by 0<n>.", source
            source.output "Your wounds don't seem to affect 0<n>!", @target
            (@target.room.occupants - [@target, source]).each_output("0<N> ignores the wounds inflicted by 1<n>.", [@target, source] )
            data[:confirm] = true
        end
    end

end

class AffectIndoors < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :hidden, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "indoors",
            keywords: ["indoors"],
            existing_affect_selection: :affect_id,
            application_type: :overwrite,
        }
    end

end

class AffectInfravision < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "infravision",
            keywords: ["infravision"],
            existing_affect_selection: :affect_id,
            application_type: :overwrite,
        }
    end

    def send_start_messages
        @target.room.occupants.each_output "0<N>'s eyes glow red.", [@target]
    end

    def send_complete_messages
        @target.output "You no longer see in the dark."
    end
end

class AffectInvisibility < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            level * 60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "invisibility",
            keywords: ["invisibility"],
            existing_affect_selection: :affect_id,
            application_type: :overwrite,
        }
    end

    def start
        add_event_listener(@target, :on_start_combat, :do_remove_affect)
        add_event_listener(@target, :try_can_be_seen, :do_invisibility)
        add_event_listener(@target, :calculate_long_auras, :do_invisibility_aura)
    end

    def send_start_messages
    	@target.room.occupants.each_output "0<N> fade0<,s> from existence.", [@target]
    end

    def send_complete_messages
        @target.room.occupants.each_output "0<N> fade0<,s> into existence.", [@target]
    end

    def do_remove_affect(data)
        clear
    end

    def do_invisibility(data)
        detect_data = { success: false }
        Game.instance.fire_event(data[:observer], :try_detect_invis, detect_data)
        if !detect_data[:success]
            data[:chance] = 0
        end
    end

    def do_invisibility_aura(data)
        data[:description] = "(Invis) " + data[:description]
    end

end
