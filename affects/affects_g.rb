require_relative 'affect.rb'

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
