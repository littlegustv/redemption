require_relative 'affect.rb'

class AffectFireRune < Affect

    def initialize(source:, target:, level:)
        super(
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
    		@source.broadcast "%s has been engulfed in flames!", @source.target({ room: @target, not: data[:mobile] }), [data[:mobile]]
	        source.magic_hit data[:mobile], 100, "fireball", "flaming"
	    else
	    	data[:mobile].output "You sense the power of the room's rune and avoid it!"
	    end
    end

end