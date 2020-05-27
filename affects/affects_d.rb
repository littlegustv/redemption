require_relative 'affect.rb'

# this is NORMAL darkness, for the room affect, not the super-dark that black dragons get

class AffectDark < Affect

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
            name: "dark",
            keywords: ["dark"],
            existing_affect_selection: :affect_id,
            application_type: :single,
        }
    end

    def start
        add_event_listener(@target, :event_try_can_see_room, :do_dark)
    end

    def do_dark( data )
        if data[:observer].affected?("dark_vision")
            #nothing
        elsif !@target.affected?("indoors") && Game.instance.daytime?  # a dark room in daytime is lit by the sun (if it is outside)
            # nothing
        elsif !data[:observer].equipped(Light).empty?     # a dark room is lit by an equipped light
            # nothing
        elsif data[:target].affected? "glowing"             # a glowing item is visible even in darkness
            # nothing
        elsif data[:observer].affected?("infravision") && ["Mobile", "Player"].include?(data[:target].class.to_s)
            # nothing
        else
            data[:chance] *= 0
        end
    end

end

class AffectDarkness < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            9 + level, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "darkness",
            keywords: ["darkness"],
            existing_affect_selection: :affect_id,
            application_type: :single,
        }
    end

    def start
        add_event_listener(@target, :event_try_can_see_room, :do_dark)
        add_event_listener(@target, :event_calculate_room_description, :darkness_description)
    end

    def darkness_description(data)
        data[:extra_show] += "\nA cloud of inpenetrable darkness covers the room!"
    end

    def send_start_messages
        @target.occupants.each_output "0<N> plunge0<,s> the room into total darkness!", [@source]
    end

    def send_complete_messages
        @target.occupants.each_output "The cloud of darkness is lifted from the room."
    end

    def do_dark( data )
        if data[:observer].affected?("dark_vision")
            # nothing
        else
            data[:chance] *= 0
        end
    end

end

class AffectDarkvision < Affect

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
            name: "darkvision",
            keywords: ["darkvision"],
            existing_affect_selection: :affect_id,
            application_type: :single,
        }
    end

end

class AffectDeathRune < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            120, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "death rune",
            keywords: ["death rune", "rune"],
            existing_affect_selection: :affect_id,
            application_type: :overwrite,
        }
    end

    def start
        add_event_listener(@target, :event_on_die, :do_death_rune)
    end

    def send_start_messages
        @target.room.occupants.each_output "0<N> scribe0<,s> a rune of death on 0<p> chest.", [@target]
    end

    def send_refresh_messages
        @target.output "You refresh your rune of death."
    end

    def send_complete_messages
        @target.output "The rune of death on your chest vanishes."
    end

    def do_death_rune( data )
        @target.room.occupants.each_output "A rune of death suddenly explodes!"
        ( @level * 3 ).times do
            (@target.room.area.occupants - @target.room.occupants).each_output "A flaming meteor crashes into the ground nearby and explodes!"
            ( @target.room.occupants - [@target] ).each do |victim|
                victim.receive_damage(@target, 100, :meteor_impact)
            end
        end
    end

end

class AffectDetectInvisibility < Affect

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
            name: "detect invisibility",
            keywords: ["detect invisibility"],
            existing_affect_selection: :affect_id,
            application_type: :overwrite,
        }
    end

    def send_start_messages
        @target.output "Your eyes tingle."
    end

    def send_complete_messages
        @target.output "You can no longer detect invisibility."
    end

    def start
        add_event_listener(@target, :event_try_detect_invis, :do_detect_invis)
    end

    def do_detect_invis(data)
        data[:success] = true
    end
end
