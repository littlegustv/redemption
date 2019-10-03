require_relative 'affect.rb'

class AffectCorrosive < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["corrosive"],
            name: "corrosive",
            modifiers: {ac_pierce: -10, ac_slash: -10, ac_bash: -10},
            level:  level,
            duration: 30,
            application_type: :global_stack
        )
    end

    def send_start_messages
        @target.broadcast "{g%s flesh burns away, revealing vital areas!{x", @game.target({ not: @target, list: @target.room.occupants }), [@target]
        @target.output "{gChunks of your flesh melt away, exposing vital areas!{x"
    end

    def send_refresh_messages
        @target.broadcast "{g%s flesh burns away, revealing vital areas!{x", @game.target({ not: @target, list: @target.room.occupants }), [@target]
        @target.output "{gChunks of your flesh melt away, exposing vital areas!{x"
    end

    def send_complete_messages
        @target.output "Your flesh begins to heal."
    end

end
