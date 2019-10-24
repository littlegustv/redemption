require_relative 'affect.rb'

class AffectScramble < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["scramble"],
            name: "scramble",
            level:  level,
            duration: 30 * level,
            modifiers: { none: 0 }
        )
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

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["shackle"],
            name: "shackle",
            level:  level,
            duration: 5,
            modifiers: { none: 0 }
        )
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

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["shackle rune", "rune"],
            name: "shackle rune",
            level:  level,
            duration: 120
        )
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
            data[:mobile].apply_affect( AffectShackle.new(source: @source, target: data[:mobile], level: @source.level, game: @game) )
        end
    end

    def shackle_rune_description(data)
        data[:extra_show] += "\nA rune is on the floor, glowing a deep green."
    end

end

class AffectShield < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["shield", "armor"],
            name: "shield",
            level: level,
            duration: level * 60,
            modifiers: { ac_pierce: 20, ac_bash: 20, ac_slash: 20, ac_magic: -20 }
        )
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

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["shopkeeper"],
            name: "shopkeeper",
            level: 0,
            permanent: true,
            modifiers: { none: 0 }
        )
    end
end

class AffectShocking < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["shocking"],
            name: "shocking",
            level:  level,
            duration: 6,
            modifiers: {success: -10}
        )
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

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["sneak"],
            name: "sneak",
            level:  level,
            duration: level.to_i * 60,
            modifiers: { none: 0 }
        )
    end

    def send_start_messages
        @target.output "You attempt to move silently."
    end

    def send_complete_messages
        @target.output "You are now visible."
    end

end

class AffectSleep < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["sleep"],
            name: "sleep",
            level:  level,
            duration: 15,
            modifiers: { none: 0 }
        )
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

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["slow"],
            name: "slow",
            level:  level,
            duration: 60,
            modifiers: { attack_speed: -1 }
        )
    end

    def send_start_messages
        @target.output "You find yourself moving more slowly."
    end

    def send_complete_messages
        @target.output "You speed up."
    end
end

class AffectStoneSkin < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["stoneskin", "armor"],
            name: "stoneskin",
            level: level,
            duration: level * 60,
            modifiers: { ac_pierce: 40 }
        )
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

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["stun"],
            name: "stun",
            level:  level,
            duration: 2,
            modifiers: { success: -50 },
        )
    end

    def send_start_messages
        @target.output "Bands of force crush you, leaving you stunned momentarily."
        @target.broadcast "Bands of force stun %s momentarily.", @target.room.occupants - [@target], [@target]        
    end
end
