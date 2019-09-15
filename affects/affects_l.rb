require_relative 'affect.rb'

class AffectLivingStone < Affect

    def initialize(source:, target:, level:)
        super(
            source: source,
            target: target,
            keywords: ["living stone"],
            name: "living stone",
            level:  level,
            duration: 60,
            modifiers: { damroll: 20, hitroll: 20, attack_speed: 3, ac_pierce: -20, armor_slash: -20 }
        )
    end

    def start
        @target.output "You are now affected by stone form."
    end

    def complete
        @target.output "Your flesh feels more supple."
    end

end
