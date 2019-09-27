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
            permanent: true,
            hidden: true
        )
    end

    def hook
        @target.add_event_listener(:event_mobile_enter, self, :do_guard)
    end

    def unhook
        @target.delete_event_listener(:event_mobile_enter, self)
    end

    def do_guard(data)
        if @target.can_see?(data[:mobile]) && data[:mobile].affected?("killer")
        	@target.do_command "yell #{data[:mobile]} is a KILLER!  PROTECT THE INNOCENT!!  BANZAI!!"
        	@target.start_combat data[:mobile]
        	data[:mobile].start_combat @target
        end
    end
end