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
        @target.add_event_listener(:event_calculate_damage, self, :do_resist)
        @target.add_event_listener(:event_display_resists, self, :do_display)
    end

    def complete
        @target.delete_event_listener(:event_calculate_damage, self)
        @target.delete_event_listener(:event_display_resists, self)
    end

    def do_resist(data)
        if data[:target] == @target && data[:element] == @data[:element]
            data[:damage] = (data[:damage] * 0.7).to_i
        end
    end

    def do_display(data)
        p @data[:element]
        element_string = Constants::Element::STRINGS[@data[:element]]
        data[:string] += "\nYou are resistant to #{element_string} damage."
    end

end
