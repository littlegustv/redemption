require_relative 'affect.rb'

class AffectZeal < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            0, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "zeal",
            keywords: ["zeal"],
            application_type: :global_single,
        }
    end

    def start
    	Game.instance.add_event_listener(@target, :event_calculate_weapon_hit_damage, self, :do_zeal)
    end

    def send_start_messages
        @target.output "You begin to channel pain into a zealous wrath!"
    end

    def complete
		Game.instance.remove_event_listener(@target, :event_calculate_weapon_hit_damage, self)
    end

    def send_complete_messages
        @target.output "Your combat abilities returns to normal."
    end

    def do_zeal( data )
    	data[:damage] *= ( 1 + ( [50 - @target.condition_percent, 0].max / 50.0 ) )
    end
end
