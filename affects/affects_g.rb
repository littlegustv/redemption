require_relative 'affect.rb'

class AffectGiantStrength < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            120, # duration
            { strength: 1 + level / 12 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "giant strength",
            keywords: ["giant strength"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.room.occupants.each_output "0<N>'s muscles surge with heightened power!", @target
    end

    def send_complete_messages
        @target.output "You feel weaker."
    end
end

class AffectGlowing < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            level * 60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "glowing",
            keywords: ["glowing"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.room.occupants.each_output "0<N> glows with a white light.", [@target]
    end

    def send_complete_messages
        @target.room.occupants.each_output "0<N> loses its glow.", [@target]
    end

    def start
        add_event_listener(@target, :event_calculate_long_auras, :do_glowing_aura)
    end

    def do_glowing_aura(data)
        data[:description] = "(Glowing) " + data[:description]
    end

end

class AffectGrandeur < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "grandeur",
            keywords: ["grandeur", "grandeurminimation"],
            application_type: :global_single,
        }
    end

    def start
        add_event_listener(@target, :event_show_condition, :do_condition)
    end

    def send_start_messages
        @target.output "You're not quite dead yet!"
        (@target.room.occupants - [@target]).each_output "%N suddenly looks almost dead.", [@target]
    end

    def send_complete_messages
        @target.output "You do not look so tough anymore."
        (@target.room.occupants - [@target]).each_output "%N now appears a lot stronger.", [ @target ]
    end

    def do_condition(data)
        data[:percent] = 100
    end
end

class AffectGuard < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            1, # period: nil
            false, # permanent: false
            Visibility::HIDDEN, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "guard",
            keywords: ["guard"],
            application_type: :global_overwrite,
        }
    end

    #
    def start
        add_event_listener(@target, :event_observe_mobile_enter, :toggle_guard)
    end

    def toggle_guard(data)
        toggle_periodic(rand * 3)
    end

    def periodic
        players = @target.room.players
        if !players || players.empty?
            toggle_periodic(nil)
            return
        end
        if !@target.attacking
            player = players.select{ |t| t.affected?("killer") && @target.can_see?(t) }.shuffle!.first
            if player
            	@target.do_command "yell #{player} is a KILLER! PROTECT THE INNOCENT!! BANZAI!!"
                @target.start_combat player
                @target.do_round_of_attacks(player)
            end
        end
    end
end
