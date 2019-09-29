require_relative 'affect.rb'

class AffectInvisibility < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["invisibility"],
            name: "invisibility",
            level:  level,
            duration: level.to_i * 60,
            modifiers: { none: 0 }
        )
    end

    def hook
        @target.output "You fade out of existence."
    	@game.broadcast "%s fades from existence.", @game.target({ room: @target.room, not: @target }), [@target]
        @target.add_event_listener(:event_on_start_combat, self, :do_remove_affect)
        @target.add_event_listener(:event_try_can_see, self, :do_invisibility)
        @target.add_event_listener(:event_calculate_description, self, :do_invisibility_aura)
    end

    def unhook
        @target.delete_event_listener(:event_on_start_combat, self)
        @target.delete_event_listener(:event_try_can_see, self)
        @target.delete_event_listener(:event_calculate_description, self)
        @target.output "You fade into existence."
        @game.broadcast "%s fades into existence.", @game.target({ room: @target.room, not: @target }), [@target]
    end

    def do_remove_affect(data)
        @target.remove_affect("invisibility")
    end

    def do_invisibility(data)
    	if data[:target] == @target
	        data[:chance] *= 0 unless data[:source].affected? "detect invisibility"
	    end
    end

    def do_invisibility_aura(data)
        data[:description] = "(Invis) " + data[:description]
    end

end

