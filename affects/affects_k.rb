require_relative 'affect.rb'

class AffectKiller < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["killer"],
            name: "killer",
            level:  0,
            duration: 1,
            permanent: true,
            hidden: true
        )
    end

    def start
        @game.add_event_listener(@target, :event_calculate_description, self, :do_killer_flag)
    end

    def complete
        @game.remove_event_listener(@target, :event_calculate_description, self)
    end

    def do_killer_flag(data)
        data[:description] = "{R(KILLER){x " + data[:description]
    end

    def send_start_messages
        @target.output "*** You are now a KILLER!! ***"
    end
end
