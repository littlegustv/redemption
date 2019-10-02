require_relative 'affect.rb'

class AffectVuln < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["vuln"],
            name: "vuln",
            level:  level,
            permanent: true,
            hidden: true,
            application_type: :multiple
        )
        @data[:element] = -1 # this gets set from outside of this class
    end

    def start
        @target.add_event_listener(:event_calculate_damage, self, :do_vuln)
        @target.add_event_listener(:event_display_vulns, self, :do_display)
    end

    def complete
        @target.delete_event_listener(:event_calculate_damage, self)
        @target.delete_event_listener(:event_display_vulns, self)
    end

    def do_vuln(data)
        if data[:target] == @target && data[:element] == @data[:element]
            data[:damage] = (data[:damage] * 1.3).to_i
        end
    end

    def do_display(data)
        element_string = Constants::Element::STRINGS[@data[:element]]
        data[:string] += "\nYou are vulnerable to #{element_string} damage."
    end

end
