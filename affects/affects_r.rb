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
        add_event_listener(@target, :event_calculate_regeneration, :do_regeneration_bonus)
        add_event_listener(@target, :event_on_hit, :do_regeneration_recovery)
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
        element = Game.instance.elements[@data[:element_id]]
        event = "event_get_#{element.name}_resist".to_sym
        add_event_listener(@target, event, :do_resist)
    end

    def do_resist(data)
        data[:value] += @data[:value]
    end

end
