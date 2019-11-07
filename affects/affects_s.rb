require_relative 'affect.rb'

class AffectScramble < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
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
        @game.add_event_listener(@target, :event_communicate, self, :do_scramble)
    end

    def complete
        @game.remove_event_listener(@target, :event_communicate, self)
    end

    def send_start_messages
        @target.output "Your mother tongue now eludes you."
        @target.broadcast "%s can no longer understand anything.", @target.room.occupants - [@target], [ @target ]
    end

    def send_complete_messages
        @target.output "Your linguistic skills return to you."
        @target.broadcast "%s remembers how to speak.", @target.room.occupants - [@target], [ @target ]
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

    def initialize(source, target, level, game)
        super(
            game, # game
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
        @game.add_event_listener(@target, :event_mobile_enter, self, :do_shackles)
    end

    def complete
        @game.remove_event_listener(@target, :event_mobile_enter, self)
    end

    def send_start_messages
        @target.output "You are bound and restricted by runic shackles!"
        @target.broadcast "%s has been bound by runic shackles!", @target.room.occupants - [@target], [ @target ]
    end

    def send_complete_messages
        @target.output "You feel less restricted in movement."
    end

    def do_shackles(data)
        @target.broadcast "%s tries to move while magically shackled.", @target.room.occupants - [@target], [@target]
        @target.output "You struggle against the shackles!"
        @target.lag += 1
    end

end

class AffectShackleRune < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
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
        @game.add_event_listener(@target, :event_calculate_room_description, self, :shackle_rune_description)
        @game.add_event_listener(@target, :event_room_mobile_enter, self, :do_shackle_rune)
    end

    def complete
        @game.remove_event_listener(@target, :event_calculate_room_description, self)
        @game.remove_event_listener(@target, :event_room_mobile_enter, self)
    end

    def send_complete_mesages
        @source.output "You feel that movement is not being restricted by runes as much as it used to."
        @source.broadcast "The rune of warding on this room vanishes.", @target.occupants
    end

    def do_shackle_rune(data)
        if data[:mobile] == @source # || rand(0..100) < 50
            data[:mobile].output "You sense the power of the room's rune and avoid it!"
        else
            data[:mobile].apply_affect( AffectShackle.new( @source, data[:mobile], @source.level, @game ) )
        end
    end

    def shackle_rune_description(data)
        data[:extra_show] += "\nA rune is on the floor, glowing a deep green."
    end

end

class AffectShield < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
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
        @target.output "You are surrounded by a force shield."
        @target.broadcast "%s is surrounded by a force shield.", @target.room.occupants - [@target], [@target]
    end

    def send_complete_messages
        @target.output "Your force shield shimmers then fades away."
    end

end

class AffectShopkeeper < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
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

class AffectShocking < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
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
        @target.broadcast "{y%s jerks and twitches from the shock!{x", @target.room.occupants - [@target], [@target]
        @target.output "{yYour muscles stop responding.{x"
    end

    def send_refresh_messages
        @target.broadcast "{y%s jerks and twitches from the shock!{x", @target.room.occupants - [@target], [@target]
        @target.output "{yYour muscles stop responding.{x"
    end
end

class AffectSneak < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
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

    def initialize(source, target, level, game)
        super(
            game, # game
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
        @game.add_event_listener(@target, :event_try_wake, self, :do_slept)
    end

    def complete
        @target.position = Constants::Position::STAND
        @game.remove_event_listener(@target, :event_try_wake, self)
    end

    def send_start_messages
        @target.output "You feel very sleepy ..... zzzzzz."
    end

    def do_slept(data)
        data[:success] = false
    end

end

class AffectSlow < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
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
    end

    def send_complete_messages
        @target.output "You speed up."
    end
end

class AffectStoneSkin < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
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
            name: "stoneskin",
            keywords: ["stoneskin", "armor"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.output "Your skin turns to stone."
        @target.broadcast "%s's skin turns to stone.", @target.room.occupants - [@target], [@target]
    end

    def send_complete_messages
        @target.output "Your skin feels soft again."
    end

end

class AffectStun < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
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
        @target.broadcast "Bands of force stun %s momentarily.", @target.room.occupants - [@target], [@target]
    end
end
