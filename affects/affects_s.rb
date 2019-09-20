require_relative 'affect.rb'

class AffectSneak < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["sneak"],
            name: "sneak",
            level:  level,
            duration: level.to_i * 60,
            modifiers: { none: 0 }
        )
    end

    def start
        @target.output "You attempt to move silently."
    end

    def complete
        @target.output "You are now visible."
    end
end

class AffectSlow < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["slow"],
            name: "slow",
            level:  level,
            duration: 60,
            modifiers: { attack_speed: -1 }
        )
    end

    def start
        @target.output "You find yourself moving more slowly."
    end

    def complete
        @target.output "You speed up."
    end
end

class AffectStun < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["stun"],
            name: "stun",
            level:  level,
            duration: 60,
            modifiers: { none: 0 }
        )
    end

    def start
        @target.output "You are stunned but will probably recover."
    end

    def complete
        @target.output "You are no longer stunned."
    end
end
