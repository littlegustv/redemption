require_relative 'affect.rb'

class AffectFireBlind < AffectBlind

    def initialize(source:, target:, level:, game:)
        super
        @keywords = ["fireblind", "blind"]
        @name = "fireblind"
    end

    def start
        @target.broadcast "{r%s is blinded by smoke!{x", @game.target({ not: @target, room: @target.room }), [@target]
        @target.output "{rYour eyes tear up from smoke...you can't see a thing!{x"
    end

    def complete
        @target.output "The smoke leaves your eyes."
    end

end

class AffectFireRune < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["fire rune", "rune"],
            name: "fire rune",
            level:  level,
            duration: 75 * level
        )
    end

    def hook
        @target.add_event_listener(:event_mobile_enter, self, :do_fire_rune)
    end

    def unhook
        @target.delete_event_listener(:event_mobile_enter, self)
    end

    def do_fire_rune(data)
    	if data[:mobile] == @source
    		@source.output "You sense the power of the room's rune and avoid it!"
    	elsif rand(0..100) < 50
    		data[:mobile].output "You are engulfed in flames as you enter the room!"
    		data[:mobile].broadcast "%s has been engulfed in flames!", @game.target({ room: @target, not: data[:mobile] }), [data[:mobile]]
	        @source.magic_hit data[:mobile], 100, "fireball", "flaming"
            # data[:mobile].anonymous_damage(100, "flaming", true, "A fire rune's blast")
	    else
	    	data[:mobile].output "You sense the power of the room's rune and avoid it!"
	    end
    end

end

class AffectFlooding < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["flooding", "slow"],
            name: "heavy 'n wet'",
            modifiers: { attack_speed: -1, dex: -1 },
            level:  level,
            duration: 30,
            application_type: :source_overwrite
        )
    end

    def start
        @target.broadcast "{b%s coughes and chokes on the water.{x", @game.target({ not: @target, room: @target.room }), [@target]
        @target.output "{bYou cough and choke on the water.{x"
    end

    def refresh
        @target.broadcast "{b%s coughes and chokes on the water.{x", @game.target({ not: @target, room: @target.room }), [@target]
        @target.output "{bYou cough and choke on the water.{x"
    end

    def complete
        @target.output "Your flesh begins to heal."
    end

end

class AffectFrost < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["frost"],
            name: "frost",
            modifiers: {str: -2},
            level:  level,
            duration: 30,
            application_type: :global_stack
        )
    end

    def start
        @target.broadcast "{C%s turns blue and shivers.{x", @game.target({ not: @target, room: @target.room }), [@target]
        @target.output "{CA chill sinks deep into your bones.{x"
    end

    def refresh
        @target.broadcast "{C%s turns blue and shivers.{x", @game.target({ not: @target, room: @target.room }), [@target]
        @target.output "{CA chill sinks deep into your bones.{x"
    end

    def complete
        @target.output "You start to warm up."
    end

end
