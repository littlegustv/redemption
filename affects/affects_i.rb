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
        @game.add_event_listener(@target, :event_override_receive_damage, self, :do_ignore_wounds)
    end

    def complete
        @game.remove_event_listener(@target, :event_override_receive_damage, self)
    end

    def send_start_messages
        @target.output "You close your eyes and forget about the pain."
        @target.broadcast "%s closes %x eyes and forgets about the pain.", @target.room.occupants - [@target], [@target]
    end

    def end_complete_messages
        @target.output "Your body is once again vulnerable."
    end

    def do_ignore_wounds(data)
        source = data[:source]
        if source && data[:confirm] == false && @target.attacking != source && rand(1..100) <= 50
            @target.output "You ignore the wounds inflicted by %s.", source
            source.output "Your wounds don't seem to affect %s!", @target
            @target.broadcast("%s ignores the wounds inflicted by %s.", @target.room.occupants - [@target, source], [@target, source] )
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
        @game.add_event_listener(@target, :event_calculate_receive_damage, self, :do_immune)
        @game.add_event_listener(@target, :event_display_immunes, self, :do_display)
    end

    def complete
        @game.remove_event_listener(@target, :event_calculate_receive_damage, self)
        @game.remove_event_listener(@target, :event_display_immunes, self)
    end

    def do_immune(data)
        if data[:element] == @data[:element]
            data[:immune] = true
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
        @game.add_event_listener(@target, :event_on_start_combat, self, :do_remove_affect)
        @game.add_event_listener(@target, :event_try_can_be_seen, self, :do_invisibility)
        @game.add_event_listener(@target, :event_calculate_aura_description, self, :do_invisibility_aura)
    end

    def complete
        @game.remove_event_listener(@target, :event_on_start_combat, self)
        @game.remove_event_listener(@target, :event_try_can_be_seen, self)
        @game.remove_event_listener(@target, :event_calculate_aura_description, self)
    end

    def send_start_messages
        @target.output "You fade out of existence."
    	@game.broadcast "%s fades from existence.", @target.room.occupants - [@target], [@target]
    end

    def send_complete_messages
        @target.output "You fade into existence."
        room  = @target.room
        @game.broadcast "%s fades into existence.", @target.room.occupants - [@target], [@target]
    end

    def do_remove_affect(data)
        clear
    end

    def do_invisibility(data)
        detect_data = { success: false }
        @game.fire_event(data[:observer], :event_try_detect_invis, detect_data)
        if !detect_data[:success]
            data[:chance] = 0
        end
    end

    def do_invisibility_aura(data)
        data[:description] = "(Invis) " + data[:description]
    end

end
