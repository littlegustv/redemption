require_relative 'affect.rb'

class AffectPoison < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["poison"],
            name: "poison",
            level:  level,
            duration: 180,
            modifiers: { str: -1 },
            period: 10
        )
    end

    def start
        @target.output "You feel very sick."
    end

    def periodic
        @target.output "You shiver and suffer."
        @target.damage 10, @target
    end

    def complete
        @target.output "You feel better!"
    end

    def summary
        super + "\n" + (" " * 24) + " : damage over time for #{ duration } hours"
    end
end
