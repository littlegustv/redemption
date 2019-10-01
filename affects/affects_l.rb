require_relative 'affect.rb'

class AffectLivingStone < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["living stone"],
            name: "living stone",
            level:  level,
            duration: 60,
            modifiers: { damroll: 20, hitroll: 20, attack_speed: 3, ac_pierce: -20, armor_slash: -20 }
        )
    end

    def send_start_messages
        @target.output "You are now affected by stone form."
        @target.broadcast("%s's flesh turns to stone.", @target.target({list: @target.room, not: @target}), [@target] )
    end

    def send_complete_messages
        @target.output "Your flesh feels more supple."
        @target.broadcast("%s's flesh looks more supple.", @target.target({list: @target.room, not: @target}), [@target] )
    end

end
