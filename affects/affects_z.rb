require_relative 'affect.rb'

class AffectZeal < Affect

    def initialize(source:)
        super(
            source: source,
            target: source,
            keywords: ["zeal"],
            name: "zeal",
            level:  1,
            permanent: true,
            modifiers: { none: 0 },
        )
    end

    def start
    	@target.add_event_listener(:event_calculate_damage, self, :do_zeal)
    end

    def send_start_messages
        @target.output "You begin to channel pain into a zealous wrath!"
    end

    def complete
		@target.add_event_listener(:event_calculate_damage, self)
    end

    def send_complete_messages
        @target.output "Your combat abilities returns to normal."
    end

    def do_zeal( data )
    	data[:damage] *= ( 1 + ( [50 - @target.condition_percent, 0].max / 50.0 ) )
    end
end
