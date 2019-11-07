require_relative 'affect.rb'

class AffectVuln < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            Constants::AffectVisibility::HIDDEN, # visibility
            true # savable
        )
        @data = { element: -1 } # this gets set from outside of this class
    end

    def self.affect_info
        return @info || @info = {
            name: "vuln",
            keywords: ["vuln"],
            application_type: :multiple,
        }
    end

    def start
        @game.add_event_listener(@target, :event_calculate_receive_damage, self, :do_vuln)
        @game.add_event_listener(@target, :event_display_vulns, self, :do_display)
    end

    def complete
        @game.remove_event_listener(@target, :event_calculate_receive_damage, self)
        @game.remove_event_listener(@target, :event_display_vulns, self)
    end

    def do_vuln(data)
        if data[:element] == @data[:element]
            data[:damage] = (data[:damage] * Constants::Damage::VULN_MULTIPLIER).to_i
        end
    end

    def do_display(data)
        element_string = Constants::Element::STRINGS[@data[:element]]
        data[:string] += "\nYou are vulnerable to #{element_string} damage."
    end

end
