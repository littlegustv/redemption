require_relative 'affect.rb'

class AffectWeaken < Affect

    def initialize(source, target, level, game)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["weaken"],
            name: "weaken",
            modifiers: {str: -10},
            level:  level,
            duration: 30 * level,
            application_type: :global_overwrite
        )
    end

    def send_start_messages
        @target.broadcast "%s looks tired and weak.", @target.room.occupants - [@target], [@target]
        @target.output "You feel your strength slip away."
    end

    def send_refresh_messages
        @target.broadcast "%s looks tired and weak.", @target.room.occupants - [@target], [@target]
        @target.output "You feel your strength slip away."
    end

    def send_complete_messages
        @target.output "You feel stronger."
    end

end
