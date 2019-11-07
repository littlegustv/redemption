require_relative 'affect.rb'

class AffectTaunt < Affect

    def initialize(source, target, level, game)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["taunt"],
            name: "taunt",
            level:  level,
            duration: level * 25,
            modifiers: {damroll: 7, hitroll: 7 },
            application_type: :global_single
        )
    end

    def send_start_messages
        @target.broadcast("%s is taunted by the demons!", @target.room.occupants - [@target], @target)
        @target.output "You radiate from being taunted by the demons!"
    end

    def complete
        @target.output "You are no longer being taunted."
    end
end
