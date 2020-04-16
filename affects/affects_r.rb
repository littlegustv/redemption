require_relative 'affect.rb'

class AffectRegeneration < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            30, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::PASSIVE, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "regeneration",
            keywords: ["regeneration"],
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_calculate_regeneration, self, :do_regeneration_bonus)
        Game.instance.add_event_listener(@target, :event_on_hit, self, :do_regeneration_recovery)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_calculate_regeneration, self)
        Game.instance.remove_event_listener(@target, :event_on_hit, self)
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

class AffectResistance < Affect

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
            value: 0.3
        }
    end

    def self.affect_info
        return @info || @info = {
            name: "resistance",
            keywords: ["resistance"],
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
