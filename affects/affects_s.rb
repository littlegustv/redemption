require_relative 'affect.rb'

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

    def hook
        @target.add_event_listener(:event_mobile_enter, self, :do_shackles)
    end

    def unhook
        @target.delete_event_listener(:event_mobile_enter, self)
    end

    def start
        @target.output "You are bound and restricted by runic shackles!"
        @target.broadcast "%s has been bound by runic shackles!", @target.target({ room: @target.room, not: @target }), [ @target ]
    end

    def complete
        @target.output "You feel less restricted in movement."
    end

    def do_shackles(data)
        @target.broadcast "%s tries to move while magically shackled.", @target.target({ room: @target.room, not: @target }), [ @target ]
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

    def hook
        @target.add_event_listener(:event_mobile_enter, self, :do_shackle_rune)
    end

    def unhook
        @target.delete_event_listener(:event_mobile_enter, self)
    end

    def complete
        @source.output "You feel that movement is not being restricted by runes as much as it used to."
        @source.broadcast "The rune of warding on this room vanishes.", @source.target({ room: @target })
    end

    def do_shackle_rune(data)
        if data[:mobile] == @source # || rand(0..100) < 50
            data[:mobile].output "You sense the power of the room's rune and avoid it!"
        else
            data[:mobile].apply_affect( AffectShackle.new(source: @source, target: data[:mobile], level: @source.level, game: @game) )
        end
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

    def start
        @target.broadcast "{y%s jerks and twitches from the shock!{x", @game.target({ not: @target, room: @target.room }), [@target]
        @target.output "{yYour muscles stop responding.{x"
    end

    def refresh
        @target.broadcast "{y%s jerks and twitches from the shock!{x", @game.target({ not: @target, room: @target.room }), [@target]
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

    def start
        @target.output "You attempt to move silently."
    end

    def complete
        @target.output "You are now visible."
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

    def start
        @target.output "You find yourself moving more slowly."
    end

    def complete
        @target.output "You speed up."
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
            duration: 60,
            modifiers: { none: 0 }
        )
    end

    def start
        @target.output "You are stunned but will probably recover."
    end

    def complete
        @target.output "You are no longer stunned."
    end
end
