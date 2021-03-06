require_relative 'affect.rb'

class AffectZeal < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            0, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "zeal",
            keywords: ["zeal"],
            existing_affect_selection: :affect_id,
            application_type: :single,
        }
    end

    def start
    	add_event_listener(@target, :calculate_weapon_hit_damage, :do_zeal)
    end

    def send_start_messages
        @target.output "You begin to channel pain into a zealous wrath!"
    end

    def send_complete_messages
        @target.output "Your combat abilities returns to normal."
    end

    def do_zeal( data )
    	data[:damage] *= ( 1 + ( [50 - @target.condition_percent, 0].max / 50.0 ) )
    end
end
