require_relative 'affect.rb'

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
            Constants::AffectVisibility::NORMAL, # visibility
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
        Game.instance.add_event_listener(@target, :event_calculate_long_auras, self, :do_glowing_aura)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_calculate_long_auras, self)
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
            Constants::AffectVisibility::NORMAL, # visibility
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
        Game.instance.add_event_listener(@target, :event_show_condition, self, :do_condition)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_show_condition, self)
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
            2, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::HIDDEN, # visibility
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
    # def start
    #     Game.instance.add_event_listener(@target, :event_mobile_enter, self, :do_guard)
    # end
    #
    # def complete
    #     Game.instance.remove_event_listener(@target, :event_mobile_enter, self)
    # end
    #
    # def do_guard(data)
    #     if @target.can_see?(data[:mobile]) && data[:mobile].affected?("killer") && !data[:mobile].affected?("cloak of mind")
    #     	@target.do_command "yell #{data[:mobile]} is a KILLER! PROTECT THE INNOCENT!! BANZAI!!"
    #     	@target.start_combat data[:mobile]
    #     end
    # end

    def periodic
        players = @target.room.players
        if players.empty?
            return
        end
        if !@target.attacking
            player = players.select{ |t| t.affected?("killer") && @target.can_see?(t) }.shuffle!.first
            if player
            	@target.do_command "yell #{player} is a KILLER! PROTECT THE INNOCENT!! BANZAI!!"
                @target.start_combat player
                @target.do_round_of_attacks(target: player)
            end
        end
    end
end
