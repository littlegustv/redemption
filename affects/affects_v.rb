require_relative 'affect.rb'

class AffectVulnerable < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            Visibility::HIDDEN, # visibility
            true # savable
        )
        @data = {
            element_id: -1, # this gets set from outside of this class
            value: -0.3
        }
    end

    def self.affect_info
        return @info || @info = {
            name: "vulnerable",
            keywords: ["vulnerable"],
            application_type: :multiple,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_get_resists, self, :do_resist)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_get_resists, self)
    end

    def do_resist(data)
        element = Game.instance.elements[@data[:element_id]]
        data[element] += @data[:value]
    end

end
