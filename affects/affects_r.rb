require_relative 'affect.rb'

class AffectRegeneration < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["regeneration"],
            name: "regeneration",
            level:  level,
            duration: 30,
            application_type: :global_single
        )
    end

    def start
        @game.add_event_listener(@target, :event_calculate_regeneration, self, :do_regeneration_bonus)
        @game.add_event_listener(@target, :event_on_hit, self, :do_regeneration_recovery)
    end

    def complete
        @game.remove_event_listener(@target, :event_calculate_regeneration, self)
        @game.remove_event_listener(@target, :event_on_hit, self)
    end

    def do_regeneration_bonus(data)
        data[:hp] = (data[:hp] * 1.5).to_i
    end

    def do_regeneration_recovery(data)
        if rand(0...10) < 5
            @target.output "You have already begun to recover!"
            @target.regen dice( 1, @target.level ), 0, 0
        end
    end

end

class AffectResist < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["resist"],
            name: "resist",
            level:  level,
            permanent: true,
            hidden: true,
            application_type: :multiple
        )
        @data[:element] = -1 # this gets set from outside of this class
    end

    def start
        @game.add_event_listener(@target, :event_calculate_receive_damage, self, :do_resist)
        @game.add_event_listener(@target, :event_display_resists, self, :do_display)
    end

    def complete
        @game.remove_event_listener(@target, :event_calculate_receive_damage, self)
        @game.remove_event_listener(@target, :event_display_resists, self)
    end

    def do_resist(data)
        if data[:element] == @data[:element]
            data[:damage] = (data[:damage] * Constants::Damage::RESIST_MULTIPLIER).to_i
        end
    end

    def do_display(data)
        element_string = Constants::Element::STRINGS[@data[:element]]
        data[:string] += "\nYou are resistant to #{element_string} damage."
    end

end
