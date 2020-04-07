require_relative 'affect.rb'

class AffectIgnoreWounds < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "ignore wounds",
            keywords: ["ignore wounds"],
            application_type: :global_overwrite,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_override_receive_damage, self, :do_ignore_wounds)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_override_receive_damage, self)
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

class AffectImmune < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            Visibility::HIDDEN, # visibility
            true # savable
        )
        @data = { element: -1 } # this gets set from outside of this class
    end

    def self.affect_info
        return @info || @info = {
            name: "immune",
            keywords: ["immune"],
            application_type: :multiple,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_calculate_receive_damage, self, :do_immune)
        Game.instance.add_event_listener(@target, :event_display_immunes, self, :do_display)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_calculate_receive_damage, self)
        Game.instance.remove_event_listener(@target, :event_display_immunes, self)
    end

    def do_immune(data)
        if data[:element] == @data[:element]
            data[:immune] = true
        end
    end

    def do_display(data)
        element_string = Constants::Element::STRINGS[@data[:element]]
        data[:string] += "\nYou are immune to #{element_string} damage."
    end

end

class AffectIndoors < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::HIDDEN, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "indoors",
            keywords: ["indoors"],
            application_type: :global_overwrite,
        }
    end

end

class AffectInfravision < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "infravision",
            keywords: ["infravision"],
            application_type: :global_overwrite,
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

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            level * 60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "invisibility",
            keywords: ["invisibility"],
            application_type: :global_overwrite,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_on_start_combat, self, :do_remove_affect)
        Game.instance.add_event_listener(@target, :event_try_can_be_seen, self, :do_invisibility)
        Game.instance.add_event_listener(@target, :event_calculate_long_auras, self, :do_invisibility_aura)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_on_start_combat, self)
        Game.instance.remove_event_listener(@target, :event_try_can_be_seen, self)
        Game.instance.remove_event_listener(@target, :event_calculate_long_auras, self)
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
        Game.instance.fire_event(data[:observer], :event_try_detect_invis, detect_data)
        if !detect_data[:success]
            data[:chance] = 0
        end
    end

    def do_invisibility_aura(data)
        data[:description] = "(Invis) " + data[:description]
    end

end
