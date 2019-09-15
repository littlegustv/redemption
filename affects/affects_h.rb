require_relative 'affect.rb'

class AffectHaste < Affect

    def initialize(source:, target:, level:)
        super(
            source: source,
            target: target,
            keywords: ["haste"],
            name: "haste",
            level:  level,
            duration: 120,
            modifiers: {dex: [1, (level / 10).to_i].max, attack_speed: 1}
        )
    end

    def start
        @target.output "You feel yourself moving more quickly."
    end

    def complete
        @target.output "You feel yourself slow down."
    end
end
