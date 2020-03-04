require_relative 'affect.rb'

# this is NORMAL darkness, for the room affect, not the super-dark that black dragons get

class AffectDark < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "dark",
            keywords: ["dark"],
            application_type: :global_overwrite,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_try_can_see_room, self, :do_dark)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_try_can_see_room, self)
    end

    def do_dark( data )
        if data[:observer].affected?("dark_vision")
            #nothing
        elsif !@target.affected?("indoors") && Game.instance.daytime?  # a dark room in daytime is lit by the sun (if it is outside)
            # nothing
        elsif !data[:observer].equipped("light").empty?     # a dark room is lit by an equipped light
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

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            9 + level, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "darkness",
            keywords: ["darkness"],
            application_type: :global_overwrite,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_try_can_see_room, self, :do_dark)
        Game.instance.add_event_listener(@target, :event_calculate_room_description, self, :darkness_description)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_try_can_see_room, self)
        Game.instance.remove_event_listener(@target, :event_calculate_room_description, self)
    end

    def darkness_description(data)
        data[:extra_show] += "\nA cloud of inpenetrable darkness covers the room!"
    end

    def send_start_messages
        @source.output "You plunge the room into absolute darkness!"
        Game.instance.broadcast "%s plunges the room into total darkness!", @target.occupants - [@source], [@source]
    end

    def send_complete_messages
        Game.instance.broadcast "The cloud of darkness is lifted from the room.", @target.occupants
    end

    def do_dark( data )
        if data[:observer].affected?("dark_vision")
            # nothing
        else
            data[:chance] *= 0
        end
    end

end

class AffectDarkVision < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "darkvision",
            keywords: ["darkvision"],
            application_type: :global_overwrite,
        }
    end

end

class AffectDeathRune < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            120, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "death rune",
            keywords: ["death rune", "rune"],
            application_type: :global_overwrite,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_on_die, self, :do_death_rune)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_on_die, self)
    end

    def send_start_messages
        @target.output "You scribe a rune of death on your chest."
        @target.broadcast "%s is marked by a rune of death.", @target.room.occupants - [@target], [@target]
    end

    def send_refresh_messages
        @target.output "You refresh your rune of death."
    end

    def send_complete_messages
        @target.output "The rune of death on your chest vanishes."
    end

    def do_death_rune( data )
        @target.broadcast "A rune of death suddenly explodes!", @target.room.occupants
        ( @level * 3 ).times do
            @target.broadcast "A flaming meteor crashes into the ground nearby and explodes!", @target.room.area.occupants - @target.room.occupants
            ( @target.room.occupants - [@target] ).each do |victim|
                @target.deal_damage(target: victim, damage: 100, noun:"meteor's impact", element: Constants::Element::ENERGY, type: Constants::Damage::MAGICAL)
            end
        end
    end

end

class AffectDetectInvisibility < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            level * 60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "detect invisibility",
            keywords: ["detect invisibility"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.output "Your eyes tingle."
    end

    def send_complete_messages
        @target.output "You can no longer detect invisibility."
    end

    def start
        Game.instance.add_event_listener(@target, :event_try_detect_invis, self, :do_detect_invis)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_try_detect_invis, self)
    end

    def do_detect_invis(data)
        data[:success] = true
    end
end
