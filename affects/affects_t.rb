require_relative 'affect.rb'

class AffectTaunt < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            147 + level * 3, # duration
            {damroll: 7, hitroll: 7 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
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
        @target.broadcast("%s is taunted by the demons!", @target.room.occupants - [@target], @target)
        @target.output "You radiate from being taunted by the demons!"
    end

    def complete
        @target.output "You are no longer being taunted."
    end
end
