require_relative 'affect.rb'

class AffectScramble < Affect

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
            name: "scramble",
            keywords: ["scramble"],
            application_type: :global_overwrite,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_communicate, self, :do_scramble)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_communicate, self)
    end

    def send_start_messages
        @target.output "Your mother tongue now eludes you."
        (@target.room.occupants - [@target]).each_output "0<N> can no longer understand anything.", [ @target ]
    end

    def send_complete_messages
        @target.output "Your linguistic skills return to you."
        (@target.room.occupants - [@target]).each_output "0<N> remembers how to speak.", [ @target ]
    end

    def do_scramble(data)
        # shuffles the letters, then reduces any multi-spaces to single-spacese
        data[:text] = data[:text].split("").shuffle.join("").gsub(/\s+/, " ")
    end

end

##
# In Original Redemption, shackle just increases the movement point cost.  For now, I have replaced it with some lag.
#
# Which is worse??
#

class AffectShackle < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            5, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "shackle",
            keywords: ["shackle"],
            application_type: :global_overwrite,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_mobile_enter, self, :do_shackles)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_mobile_enter, self)
    end

    def send_start_messages
        @target.output "You are bound and restricted by runic shackles!"
        (@target.room.occupants - [@target]).each_output "0<N> has been bound by runic shackles!", [ @target ]
    end

    def send_complete_messages
        @target.output "You feel less restricted in movement."
    end

    def do_shackles(data)
        (@target.room.occupants - [@target]).each_output "0<N> tries to move while magically shackled.", [@target]
        @target.output "You struggle against the shackles!"
        @target.lag += 1
    end

end

class AffectShackleRune < Affect

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
            name: "shackle rune",
            keywords: ["shackle rune", "rune"],
            application_type: :global_overwrite,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_calculate_room_description, self, :shackle_rune_description)
        Game.instance.add_event_listener(@target, :event_room_mobile_enter, self, :do_shackle_rune)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_calculate_room_description, self)
        Game.instance.remove_event_listener(@target, :event_room_mobile_enter, self)
    end

    def send_complete_mesages
        @source.output "You feel that movement is not being restricted by runes as much as it used to."
        @target.occupants.each_output "The rune of warding on this room vanishes."
    end

    def do_shackle_rune(data)
        if data[:mobile] == @source # || rand(0..100) < 50
            data[:mobile].output "You sense the power of the room's rune and avoid it!"
        else
            data[:mobile].apply_affect( AffectShackle.new( @source, data[:mobile], @source.level, Game.instance ) )
        end
    end

    def shackle_rune_description(data)
        data[:extra_show] += "\nA rune is on the floor, glowing a deep green."
    end

end

class AffectShield < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            300, # duration
            { ac_pierce: 20, ac_bash: 20, ac_slash: 20, ac_magic: -20 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "shield",
            keywords: ["shield", "armor"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.room.occupants.each_output "0<N> 0<are,is> surrounded by a force shield.", [@target]
    end

    def send_complete_messages
        @target.output "Your force shield shimmers then fades away."
    end

end

class AffectShocked < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            6, # duration
            { success: -10 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "shocking",
            keywords: ["shocking"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        (@target.room.occupants - [@target]).each_output "{y0<N> jerks and twitches from the shock!{x", [@target]
        @target.output "{yYour muscles stop responding.{x"
    end

    def send_refresh_messages
        (@target.room.occupants - [@target]).each_output "{y0<N> jerks and twitches from the shock!{x", [@target]
        @target.output "{yYour muscles stop responding.{x"
    end
end

class AffectShockingWeapon < Affect

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
        @data = {
            chance: 5
        }
    end

    def self.affect_info
        return @info || @info = {
            name: "shocking",
            keywords: ["shocking"],
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_item_wear, self, :add_flag)
        Game.instance.add_event_listener(@target, :event_item_unwear, self, :remove_flag)
        if @target.equipped?
            Game.instance.add_event_listener(@target.carrier, :event_on_hit, self, :do_flag)
        end
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_item_wear, self)
        Game.instance.remove_event_listener(@target, :event_item_unwear, self)
        if @target.equipped?
            Game.instance.remove_event_listener(@target.carrier, :event_on_hit, self)
        end
    end

    def add_flag(data)
        Game.instance.add_event_listener(@target.carrier, :event_override_hit, self, :do_flag)
    end

    def remove_flag(data)
        Game.instance.remove_event_listener(@target.carrier, :event_override_hit, self)
    end

    def do_flag(data)
        if data[:weapon] == @target && data[:target].active
            data[:target].output "You are shocked by 0<n>.", [@target]
            (data[:target].room.occupants | data[:source].room.occupants).each_output "0<N> is struck by lightning from 1<n>'s 2<n>'.", [data[:target], data[:source], @target]
            if dice(1, 100) <= @data[:chance]
                data[:target].apply_affect(AffectCorroded.new(data[:source], data[:target], @target.level))
            end
        end
    end

end

class AffectShopkeeper < Affect

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
    end

    def self.affect_info
        return @info || @info = {
            name: "shopkeeper",
            keywords: ["shopkeeper"],
            application_type: :global_overwrite,
        }
    end

end

class AffectSneak < Affect

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
            name: "sneak",
            keywords: ["sneak"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.output "You attempt to move silently."
    end

    def send_complete_messages
        @target.output "You are now visible."
    end

end

class AffectSleep < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            15, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "sleep",
            keywords: ["sleep"],
            application_type: :global_overwrite,
        }
    end

    def start
        @target.position = Constants::Position::SLEEP
        Game.instance.add_event_listener(@target, :event_try_wake, self, :do_slept)
    end

    def complete
        @target.position = Constants::Position::STAND
        Game.instance.remove_event_listener(@target, :event_try_wake, self)
    end

    def send_start_messages
        @target.output "You feel very sleepy ..... zzzzzz."
    end

    def do_slept(data)
        data[:success] = false
    end

end

class AffectSlow < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            9 + level, # duration
            { attack_speed: -1 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "slow",
            keywords: ["slow"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.output "You find yourself moving more slowly."
        (@target.room.occupants - [@target]).each_output "{y0<N> slows down.{x", [@target]
    end

    def send_complete_messages
        @target.output "You speed up."
    end
end

class AffectStoneSkin < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            300, # duration
            { ac_pierce: 40 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "stone skin",
            keywords: ["stone skin", "stoneskin", "armor"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.room.occupants.each_output "0<N>'s skin turns to stone.", [@target]
    end

    def send_complete_messages
        @target.output "Your skin feels soft again."
    end

end

class AffectStun < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            2, # duration
            { success: -50 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "stun",
            keywords: ["stun"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.output "Bands of force crush you, leaving you stunned momentarily."
        (@target.room.occupants - [@target]).each_output "Bands of force stun 0<n> momentarily.", [@target]
    end
end
