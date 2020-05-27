require_relative 'affect.rb'

class AffectRegeneration < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            30, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :passive, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "regeneration",
            keywords: ["regeneration"],
            existing_affect_selection: :affect_id,
            application_type: :single,
        }
    end

    def start
        add_event_listener(@target, :event_calculate_regeneration, :do_regeneration_bonus)
        add_event_listener(@target, :event_on_hit, :do_regeneration_recovery)
    end

    def do_regeneration_bonus(data)
        data[:hp] = (data[:hp] * 1.5)
    end

    def do_regeneration_recovery(data)
        if rand(0...10) < 5
            @target.output "You have already begun to recover!"
            @target.regen dice( 1, @target.level ), 0, 0
        end
    end

end
