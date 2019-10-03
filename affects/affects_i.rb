require_relative 'affect.rb'

class AffectIgnoreWounds < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["ignore wounds"],
            name: "ignore wounds",
            level:  level,
            duration: 60,
            modifiers: { none: 0 }
        )
    end

    def start
        @target.add_event_listener(:event_override_damage, self, :do_ignore_wounds)
    end

    def complete
        @target.delete_event_listener(:event_override_damage, self)
    end

    def send_start_messages
        @target.output "You close your eyes and forget about the pain."
        @target.broadcast "%s closes %x eyes and forgets about the pain.", @target.target( list: @target.room.occupants, not: @target ), [@target]
    end

    def end_complete_messages
        @target.output "Your body is once again vulnerable."
    end

    def do_ignore_wounds(data)
        source = data[:source]
        if source && data[:confirm] == false && @target == data[:target] && @target.attacking != source && rand(1..100) <= 50
            @target.output "You ignore the wounds inflicted by %s.", source
            source.output "Your wounds don't seem to affect %s!", @target
            @target.broadcast("%s ignores the wounds inflicted by %s.", @target.target({list: @target.room.occupants, not: [@target, source]}), [@target, source] )
            data[:confirm] = true
        end
    end

end

class AffectImmune < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["immune"],
            name: "immune",
            level:  level,
            permanent: true,
            hidden: true,
            application_type: :multiple
        )
        @data[:element] = -1 # this gets set from outside of this class
    end

    def start
        @target.add_event_listener(:event_override_damage, self, :do_vuln)
        @target.add_event_listener(:event_display_immunes, self, :do_display)
    end

    def complete
        @target.delete_event_listener(:event_override_damage, self)
        @target.delete_event_listener(:event_display_immunes, self)
    end

    def do_vuln(data)
        if data[:target] == @target && data[:element] == @data[:element]
            override[:confirm] = true
        end
    end

    def do_display(data)
        element_string = Constants::Element::STRINGS[@data[:element]]
        data[:string] += "\nYou are immune to #{element_string} damage."
    end

end

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

    def start
        @target.add_event_listener(:event_on_start_combat, self, :do_remove_affect)
        @target.add_event_listener(:event_try_can_see, self, :do_invisibility)
        @target.add_event_listener(:event_calculate_description, self, :do_invisibility_aura)
    end

    def complete
        @target.delete_event_listener(:event_on_start_combat, self)
        @target.delete_event_listener(:event_try_can_see, self)
        @target.delete_event_listener(:event_calculate_description, self)
    end

    def send_start_messages
        @target.output "You fade out of existence."
    	@game.broadcast "%s fades from existence.", @game.target({ list: @target.room.occupants, not: @target }), [@target]
    end

    def send_complete_messages
        @target.output "You fade into existence."
        @game.broadcast "%s fades into existence.", @game.target({ list: @target.room.occupants, not: @target }), [@target]
    end

    def do_remove_affect(data)
        clear
    end

    def do_invisibility(data)
    	if data[:target] == @target
	        data[:chance] *= 0 unless data[:observer].affected? "detect invisibility"
	    end
    end

    def do_invisibility_aura(data)
        data[:description] = "(Invis) " + data[:description]
    end

end
