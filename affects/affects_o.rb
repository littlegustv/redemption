require_relative 'affect.rb'

class AffectOracle < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            120, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "oracle",
            keywords: ["oracle"],
            existing_affect_selection: :affect_id,
            application_type: :single,
        }
    end

    def start
        add_event_listener(@target, :event_calculate_room_description, :oracle_description)
        add_event_listener(@target, :event_calculate_regeneration, :do_oracle)
    end

    def send_complete_messages
    	@target.occupants.each_output "The oracle fades away."
    end

    def do_oracle( data )
    	# 10% bonus to all healing!
    	if data[:mobile] == @source
    		data[:hp] *= 1.1
    		data[:mp] *= 1.1
    		data[:mv] *= 1.1
    	end
    end

    def oracle_description( data )
        data[:extra_show] += "\nAn oracle infuses your magical senses."
    end

end
