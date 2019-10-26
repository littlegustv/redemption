require_relative 'affect.rb'

class AffectGlowing < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["glowing"],
            name: "glowing",
            level:  level,
            duration: level.to_i * 60,
            modifiers: { none: 0 }
        )
    end

    def send_start_messages
        @game.broadcast "%s glows with a white light.", @target.room.occupants, [@target]
    end

    def send_complete_messages
        @game.broadcast "%s loses its glow.", @target.room.occupants, [@target]
    end

    def start
        @game.add_event_listener(@target, :event_calculate_aura_description, self, :do_glowing_aura)
    end

    def complete
        @game.remove_event_listener(@target, :event_calculate_aura_description, self)
    end

    def do_glowing_aura(data)
        data[:description] = "(Glowing) " + data[:description]
    end

end

class AffectGrandeur < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["granduer", "grandeurminimation"],
            name: "grandeur",
            level:  level,
            duration: 60 * level,
            application_type: :global_single
        )
    end

    def start
        @game.add_event_listener(@target, :event_show_condition, self, :do_condition)
    end

    def complete
        @game.remove_event_listener(@target, :event_show_condition, self)
    end

    def send_start_messages
        @target.output "You're not quite dead yet!"
        @target.broadcast "%s suddenly looks almost dead.", @target.room.occupants - [@target], [@target]
    end

    def send_complete_messages
        @target.output "You do not look so tough anymore."
        @target.broadcast "%s now appears alot stronger.", @target.room.occupants - [@target], [ @target ]
    end

    def do_condition(data)
        data[:percent] = 100
    end
end

class AffectGuard < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["guard"],
            name: "guard",
            level:  0,
            duration: 1,
            period: 2,
            permanent: true,
            hidden: true
        )
    end
    #
    # def start
    #     @game.add_event_listener(@target, :event_mobile_enter, self, :do_guard)
    # end
    #
    # def complete
    #     @game.remove_event_listener(@target, :event_mobile_enter, self)
    # end
    #
    # def do_guard(data)
    #     if @target.can_see?(data[:mobile]) && data[:mobile].affected?("killer") && !data[:mobile].affected?("cloak of mind")
    #     	@target.do_command "yell #{data[:mobile]} is a KILLER! PROTECT THE INNOCENT!! BANZAI!!"
    #     	@target.start_combat data[:mobile]
    #     end
    # end

    def periodic
        if !@target.attacking
            player = @target.room.occupants.select{ |t| t.affected?("killer") && @target.can_see?(t) }.shuffle.first
            if player
            	@target.do_command "yell #{player} is a KILLER! PROTECT THE INNOCENT!! BANZAI!!"
                @target.start_combat player
                @target.do_round_of_attacks(target: player)
            end
        end
    end
end
