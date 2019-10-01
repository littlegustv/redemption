require_relative 'affect.rb'

class AffectDetectInvisibility < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["detect invisibility"],
            name: "detect invisibility",
            level:  level,
            duration: level.to_i * 60,
            modifiers: { none: 0 }
        )
    end

    def send_start_messages
        @target.output "Your eyes tingle."
    end

    def send_complete_messages
        @target.output "You can no longer detect invisibility."
    end
end
