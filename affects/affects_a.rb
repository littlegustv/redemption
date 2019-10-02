require_relative 'affect.rb'

class AffectAlarmRune < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["alarm rune", "rune"],
            name: "alarm rune",
            level:  level,
            duration: 120,
            application_type: :source_overwrite
        )
    end

    def start
        @target.add_event_listener(:event_mobile_enter, self, :do_alarm_rune)
    end

    def complete
        @target.delete_event_listener(:event_mobile_enter, self)
        @source.remove_affect "alarm rune"
    end

    def send_complete_messages
    	@source.output "Your connection with the alarm rune is broken."
    	@source.broadcast "The rune of warding on this room vanishes.", @target.target({ room: @target })
    end

    def do_alarm_rune(data)
    	if data[:mobile] == @source
    		@source.output "You sense the power of the room's rune and avoid it!"
    	else
    		@source.output "{R%s has triggered your alarm rune!{x", [data[:mobile]]
	    end
    end

end

class AffectAggressive < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["aggressive"],
            name: "aggressive",
            level:  0,
            duration: 1,
            permanent: true,
            hidden: true
        )
    end

    def start
        @target.add_event_listener(:event_mobile_enter, self, :do_aggro)
    end

    def complete
        @target.delete_event_listener(:event_mobile_enter, self)
    end

    def do_aggro(data)
        if @target.can_see?(data[:mobile]) && !data[:mobile].affected?("cloak of mind")
            @game.broadcast "%s screams and attacks!!", @game.target({ list: @target.room.occupants, not: @target }), [@target]
            @target.start_combat data[:mobile]
            data[:mobile].start_combat @target
        end
    end
end