require_relative 'affect.rb'

class AffectWeaken < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            69 + level, # duration
            { strength: -10 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "weaken",
            keywords: ["weaken"],
            application_type: :global_single,
        }
    end

    def send_start_messages
        (@target.room.occupants - [@target]).each_output "0<N> looks tired and weak.", [@target]
        @target.output "You feel your strength slip away."
    end

    def send_refresh_messages
        (@target.room.occupants - [@target]).each_output "0<N> looks tired and weak.", [@target]
        @target.output "You feel your strength slip away."
    end

    def send_complete_messages
        @target.output "You feel stronger."
    end

end
