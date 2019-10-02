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
            period: 10,
            application_type: :source_stack
        )
    end

    def send_start_messages
        @target.broadcast "{m%s looks very ill.{x", @game.target({ not: @target, room: @target.room }), [@target]
        # @target.output "{mYou feel poison coursing through your veins.{x"
        @target.output "You feel very sick."
    end

    def send_refresh_messages
        @target.broadcast "{m%s looks very ill.{x", @game.target({ not: @target, room: @target.room }), [@target]
        # @target.output "{mYou feel poison coursing through your veins.{x"
        @target.output "You feel very sick."
    end

    def periodic
        @target.output "You shiver and suffer."
        @target.broadcast("%s shivers and suffers.", @target.target({list: @target.room.occupants, not: @target}), @target)
        @target.receive_damage(source: nil, damage: 10, element: Constants::Element::POISON, type: Constants::Damage::MAGICAL, silent: true)
    end

    def send_complete_messages
        @target.output "You feel better!"
    end

    def summary
        super + "\n" + (" " * 24) + " : damage over time for #{ duration } hours"
    end
end
