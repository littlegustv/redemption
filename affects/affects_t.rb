require_relative 'affect.rb'

class AffectTaunt < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            147 + level * 3, # duration
            {damage_roll: 7, hit_roll: 7 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "taunt",
            keywords: ["taunt"],
            application_type: :global_single,
        }
    end

    def send_start_messages
        (@target.room.occupants - [@target]).each_output("0<N> is taunted by the demons!", @target)
        @target.output "You radiate from being taunted by the demons!"
    end

    def complete
        @target.output "You are no longer being taunted."
    end
end
