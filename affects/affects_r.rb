require_relative 'affect.rb'

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
